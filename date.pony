use "files"
use "process"
use "collections"


actor Date
  let _env: Env
  let _out: OutputActor
  let _format: String val

  new create(env: Env, out: OutputActor, format: String val) =>
    _env = env
    _out = out
    _format = format

  be apply() =>
    try
      let auth = _env.root as AmbientAuth
      let monitor = ProcessMonitor(
        auth, auth,
        DateClient(this),
        FilePath(auth, "/usr/bin/date")?,
        ["date"; "+" + _format],
        _env.vars)
      monitor.done_writing()
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", "date")
    m.insert("full_text", data)
    _out.receive(consume m)


class DateClient is ProcessClient
  let _parent: Date

  new iso create(parent: Date) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let s = String.from_iso_array(consume data).>strip()
    _parent.receive(consume s)
