use "files"
use "regex"
use "collections/persistent"


actor Memory
  let _env: Env
  let _out: OutputActor
  var _state: State
  let _memtype: MemType
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State) =>
    _env = env
    _out = out
    _state = init
    _memtype = match _state.get_or_else("type", "mem")
    | "mem" => Mem
    | "swap" => Swap
    else Mem
    end
    try
      _file = File.open(FilePath(_env.root as AmbientAuth, "/proc/meminfo")?)
    end

  be apply() =>
    try
      var total: U64 = 0
      var free: U64 = 0
      let file = (_file as File).>seek_start(0)
      let s: String val = file.read_string(1000000) //file.size() doesn't work for /proc
      match _memtype
      | Mem =>
        for m in Regex("MemTotal:\\s*(\\d+)")?.matches(s) do total = m.groups()(0)?.u64()? end
        for m in Regex("(MemFree|Buffers|Cached):\\s*(\\d+)")?.matches(s) do free = free + m.groups()(1)?.u64()? end
      | Swap =>
        for m in Regex("SwapTotal:\\s*(\\d+)")?.matches(s) do total = m.groups()(0)?.u64()? end
        for m in Regex("(SwapFree):\\s*(\\d+)")?.matches(s) do free = free + m.groups()(1)?.u64()? end
      end
      let text = recover String(8) end
      text.append(_memtype.symbol())
      text.append(((1-(free.f64()/total.f64()))*100).round().string())
      text.append("%")
      _state = _state.update("full_text", consume text)
    else
      _state = _state.update("full_text", _memtype.string() + " fail")
    end
    _out.receive(_state)


type MemType is (Mem | Swap)
primitive Mem
  fun string(): String val => "Memory"
  fun symbol(): String val => "M"
primitive Swap
  fun string(): String val => "Swap"
  fun symbol(): String val => "S"
