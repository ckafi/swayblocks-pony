use "files"
use "process"
use "regex"
use "collections"


actor Volume
  let name: String val = "Volume"
  let _env: Env
  let _out: OutputActor
  let _config: Config

  new create(env: Env, out: OutputActor, config: Config) =>
    _env = env
    _out = out
    _config = config

  be apply() =>
    try
      let device = _config(name)?("device")?
      let channel = _config(name)?("channel")?
      let auth = _env.root as AmbientAuth
      let monitor = ProcessMonitor(
        auth, auth,
        VolumeClient(this),
        FilePath(auth, "/usr/bin/amixer")?,
        ["amixer"; "-M"; "-D"; device; "get"; channel],
        _env.vars)
      monitor.done_writing()
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", name)
    m.insert("full_text", "VOL" + data)
    _out.receive(consume m)


class VolumeClient is ProcessNotify
  let _parent: Volume

  new iso create(parent: Volume) =>
    _parent = parent

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    try
      let m = Regex("Front Left: .* \\[(\\d+)%\\] \\[(\\w+)\\]")?(consume data)?
      let perc: String val = m(1)? + "%"
      let stat: String val = m(2)?
      if stat == "on" then
        _parent.receive(perc)
      else
        _parent.receive("MUTE")
      end
    else
      _parent.receive("-1")
    end
