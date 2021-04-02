use "files"
use "process"
use "collections"
use "debug"


actor Fuzzytime
  let _env: Env
  let _out: OutputActor

  new create(env: Env, out: OutputActor) =>
    _env = env
    _out = out

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
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", "fuzzytime")
    m.insert("full_text", data)
    _out.receive(consume m)


class FuzzytimeClient is ProcessNotify
  let _parent: Fuzzytime

  new iso create(parent: Fuzzytime) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let s = String.from_iso_array(consume data).>strip()
    _parent.receive(consume s)
