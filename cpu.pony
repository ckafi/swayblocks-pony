use "files"
use "collections"
use "regex"


actor CPU
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso
  var _last_total: U64 = 0
  var _last_idle: U64 = 0
  var _stat: (File | None) = None

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end
    try
      _stat = File.open(FilePath(_env.root as AmbientAuth, "/proc/stat")?)
    end

  be apply() =>
    var total: U64 = 0
    var idle: U64 = 0
    var count: U8 = 0
    try
      let stat = (_stat as File).>seek_start(0)
      var s: String val = stat.read_string(1024)
      s = s.trim(0, s.find("\n")?.usize())
      for m in Regex("(\\d+)")?.matches(s) do
        let value = m[String iso](0)?.u64()?
        total = total + value
        if count == 3 then idle = value end
        count = count + 1
      end
      let perc = 1 - ((idle-_last_idle).f64()/(total-_last_total).f64())
      _state("full_text") = "CPU " + ((perc * 100).round().string()) + "%"
      _last_idle = idle
      _last_total = total
    else
      _state("full_text") = "CPU FAIL"
    end
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)
