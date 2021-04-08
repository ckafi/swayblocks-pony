use "files"
use "collections/persistent"


actor Load
  let _env: Env
  let _out: OutputActor
  var _state: State
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State) =>
    _env = env
    _out = out
    _state = init
    try
      _file = File.open(FilePath(_env.root as AmbientAuth, "/proc/loadavg")?)
    end

  be apply() =>
    try
      let file = (_file as File).>seek_start(0)
      _state = _state.update("full_text", file.read_string(1024).split()(0)?) // file.size() doesn't work for /proc/
    else
      _state = _state.update("full_text", "Load Fail")
    end
    _out.receive(_state)
