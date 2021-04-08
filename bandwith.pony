use "files"
use "collections/persistent"


actor Bandwith
  let _env: Env
  let _out: OutputActor
  var _state: State

  let _interface: String val
  let _direction: Direction
  let _factor: U64
  var _last_bytes: U64 = 0
  var _state_file: (File | None) = None
  var _bytes_file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State) =>
    _env = env
    _out = out
    _state = init
    _interface = try _state("interface")? as String else "lo" end
    _direction = match _state.get_or_else("direction", "in")
    | "in" => In
    | "out" => Out
    else In
    end
    let factor = try _state("interval")? as I64 else 0 end
    _factor = factor.u64()
    try
      let path = FilePath(_env.root as AmbientAuth, "/sys/class/net/")?.join(_interface)?
      _state_file = File.open(path.join("operstate")?)
      _bytes_file = File.open(path.join("statistics")?.join(_direction.prefix() + "_bytes")?)
    end

  be apply() =>
    try
      let state_file: File = (_state_file as File).>seek_start(0)
      if state_file.read_string(2)!= "up" then error end
      let bytes_file = (_bytes_file as File).>seek_start(0)
      let bytes = bytes_file.read_string(1024).>rstrip().u64()?
      var diff = (bytes - _last_bytes) / _factor / 1024
      let suffix = if diff >= 1024 then
        diff = diff / 1024
        "M"
      else
        "K"
      end
      _last_bytes = bytes
      let text = recover String(8) end
      text.append(_direction.string())
      text.append(diff.string())
      text.append(suffix)
      _state = _state.update("full_text", consume text)
                     .remove("color")?
    else
      _state = _state.update("full_text", _interface + " down")
                     .update("color", "#FF0000")
    end
    _out.receive(_state)


type Direction is (In | Out)
primitive In
  fun string(): String val => "In "
  fun prefix(): String val => "rx"
primitive Out
  fun string(): String val => "Out "
  fun prefix(): String val => "tx"
