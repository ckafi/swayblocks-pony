use "files"
use "regex"
use "collections"


actor Memory
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso
  let _memtype: MemType
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end
    _memtype = match _init.get_or_else("type", "mem")
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
      _state("full_text") = _memtype.symbol() + ((1-(free.f64()/total.f64()))*100).round().string() + "%"
    else
      _state("full_text") = _memtype.string() + " fail"
    end
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)


type MemType is (Mem | Swap)
primitive Mem
  fun string(): String val => "Memory"
  fun symbol(): String val => "M"
primitive Swap
  fun string(): String val => "Swap"
  fun symbol(): String val => "S"
