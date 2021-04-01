use "files"
use "collections"


actor Bandwith
  let _env: Env
  let _out: OutputActor
  let _interface: String val
  let _direction: Direction
  let _factor: U64
  var _last_bytes: U64 = 0
  var _state_file: (File | None) = None
  var _bytes_file: (File | None) = None

  new create(
    env: Env,
    out: OutputActor,
    interface': String val,
    direction: Direction,
    factor: U64)
  =>
    _env = env
    _out = out
    _interface = interface'
    _direction = direction
    _factor = factor
    try
      let path = FilePath(_env.root as AmbientAuth, "/sys/class/net/")?.join(_interface)?
      _state_file = File.open(path.join("operstate")?)
      _bytes_file = File.open(path.join("statistics")?.join(_direction.prefix() + "_bytes")?)
    end

  be apply() =>
    try
      let state_file: File = (_state_file as File).>seek_start(0)
      let state: String val = state_file.read_string(2)
      if state != "up" then error end
      let bytes_file = (_bytes_file as File).>seek_start(0)
      let bytes = bytes_file.read_string(1024).>rstrip().u64()?
      var diff = (bytes - _last_bytes) / _factor / 1024
      var suffix = "K"
      if diff >= 1024 then
        diff = diff / 1024
        suffix = "M"
      end
      receive(diff.string() + suffix)
      _last_bytes = bytes
    else
      receive("down")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", _direction.name())
    m.insert("full_text", _direction.symbol() + data)
    _out.receive(consume m)


type Direction is (In | Out)
primitive In
  fun name(): String val => "bandwith_in"
  fun symbol(): String val => "IN "
  fun prefix(): String val => "rx"
primitive Out
  fun name(): String val => "bandwith_out"
  fun symbol(): String val => "OUT "
  fun prefix(): String val => "tx"
