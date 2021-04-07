use "files"
use "collections"


actor Load
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end
    try
      _file = File.open(FilePath(_env.root as AmbientAuth, "/proc/loadavg")?)
    end

  be apply() =>
    try
      let file = (_file as File).>seek_start(0)
      _state("full_text") = file.read_string(1024).split()(0)? // file.size() doesn't work for /proc/
    else
      _state("full_text") = "Load Fail"
    end
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)
