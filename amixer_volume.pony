use "files"
use "process"
use "regex"
use "collections"


actor AmixerVolume
  let _env: Env
  let _out: OutputActor
  let _device: String val
  let _channel: String val

  new create(
    env: Env,
    out: OutputActor,
    device: String val,
    channel: String val)
  =>
    _env = env
    _out = out
    _device = device
    _channel = channel

  be apply() =>
    try
      let auth = _env.root as AmbientAuth
      let monitor = ProcessMonitor(
        auth, auth,
        AmixerClient(this),
        FilePath(auth, "/usr/bin/amixer")?,
        ["amixer"; "-M"; "-D"; _device; "get"; _channel],
        _env.vars)
      monitor.done_writing()
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", "volume")
    m.insert("full_text", "VOL" + data)
    _out.receive(consume m)


class AmixerClient is ProcessNotify
  let _parent: AmixerVolume

  new iso create(parent: AmixerVolume) =>
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
