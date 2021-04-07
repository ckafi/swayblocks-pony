use "files"
use "process"
use "collections"


actor Date
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end

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
      _state("full_text") = "Date fail"
      _send()
    end

  be receive(data: String val) =>
    _state("full_text") = data
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)


class DateClient is ProcessNotify
  let _parent: Date

  new iso create(parent: Date) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let s = String.from_iso_array(consume data).>strip()
    _parent.receive(consume s)
