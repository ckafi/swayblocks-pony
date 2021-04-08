use "files"
use "collections/persistent"
use "regex"


actor CPU
  let _env: Env
  let _out: OutputActor
  var _state: State

  var _last_total: U64 = 0
  var _last_idle: U64 = 0
  var _stat: (File | None) = None

  new create(env: Env, out: OutputActor, init: State) =>
    _env = env
    _out = out
    _state = init
    try
      _stat = File.open(FilePath(_env.root as AmbientAuth, "/proc/stat")?)
    end

  be apply() =>
    var total: U64 = 0
    var idle: U64 = 0
    var count: U8 = 0
    try
      let stat = (_stat as File).>seek_start(0)
      let s: String iso = stat.read_string(1024)
      s.trim_in_place(0, s.find("\n")?.usize())
      for m in Regex("(\\d+)")?.matches(consume s) do
        let value = m[String iso](0)?.u64()?
        total = total + value
        if count == 3 then idle = value end
        count = count + 1
      end
      let perc = 1 - ((idle-_last_idle).f64()/(total-_last_total).f64())
      let text = recover String(8) end
      text.append("CPU ")
      text.append((perc * 100).round().string())
      text.append("%")
      _state = _state.update("full_text", consume text)
      _last_idle = idle
      _last_total = total
    else
      _state = _state.update("full_text", "CPU fail")
    end
    _out.receive(_state)
