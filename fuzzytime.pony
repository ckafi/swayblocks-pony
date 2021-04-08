use "files"
use "process"
use "collections/persistent"


actor Fuzzytime
  let _env: Env
  let _out: OutputActor
  var _state: State

  new create(env: Env, out: OutputActor, init: State) =>
    _env = env
    _out = out
    _state = init

  be apply() =>
    try
      let auth = _env.root as AmbientAuth
      let monitor = ProcessMonitor(
        auth, auth,
        FuzzytimeClient(this),
        FilePath(auth, "/home/tobias/bin/fuzzytime")?,
        ["fuzzytime"],
        _env.vars)
      monitor.done_writing()
    else
      _state = _state.update("full_text", "Time fail")
      _out.receive(_state)
    end

  be receive(data: String val) =>
    _state = _state.update("full_text", data)
    _out.receive(_state)


class FuzzytimeClient is ProcessNotify
  let _parent: Fuzzytime

  new iso create(parent: Fuzzytime) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let s = String.from_iso_array(consume data).>strip()
    _parent.receive(consume s)
