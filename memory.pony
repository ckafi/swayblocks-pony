use "files"
use "regex"
use "collections"


actor Memory
  let _env: Env
  let _out: OutputActor
  let _memtype: MemType
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor, memtype: MemType) =>
    _env = env
    _memtype = memtype
    _out = out
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
      receive(((1-(free.f64()/total.f64()))*100).round().string())
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", _memtype.name())
    m.insert("full_text", _memtype.symbol() + data + "%")
    _out.receive(consume m)


type MemType is (Mem | Swap)
primitive Mem
  fun name(): String val => "memory"
  fun symbol(): String val => "M"
primitive Swap
  fun name(): String val => "swap"
  fun symbol(): String val => "S"
