use "files"
use "process"
use "collections/persistent"


actor Date
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
        DateClient(this),
        FilePath(auth, "/usr/bin/date")?,
        ["date"; "+" + (_state("format")? as String)],
        _env.vars)
      monitor.done_writing()
    else
      _state = _state.update("full_text", "Date fail")
      _out.receive(_state)
    end

  be receive(data: String val) =>
    _state = _state.update("full_text", data)
    _out.receive(_state)


class DateClient is ProcessNotify
  let _parent: Date

  new iso create(parent: Date) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let s = String.from_iso_array(consume data).>strip()
    _parent.receive(consume s)
