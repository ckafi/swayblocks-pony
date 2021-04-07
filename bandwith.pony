use "files"
use "collections"


actor Bandwith
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso
  let _interface: String val
  let _direction: Direction
  let _factor: U64
  var _last_bytes: U64 = 0
  var _state_file: (File | None) = None
  var _bytes_file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end
    _interface = try _init("interface")? as String else "lo" end
    _direction = match _init.get_or_else("direction", "in")
    | "in" => In
    | "out" => Out
    else In
    end
    let factor = try _init("interval")? as I64 else 0 end
    _factor = factor.u64()
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
      _last_bytes = bytes
      _state("full_text") = diff.string() + suffix
    else
      _state("full_text") = _interface + " down"
      _state("color") = "#FF0000"
    end
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)


type Direction is (In | Out)
primitive In
  fun string(): String val => "In "
  fun prefix(): String val => "rx"
primitive Out
  fun string(): String val => "Out "
  fun prefix(): String val => "tx"
