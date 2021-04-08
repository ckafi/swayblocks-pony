use "files"
use "process"
use "regex"
use "collections/persistent"


actor Volume
  let _env: Env
  let _out: OutputActor
  var _state: State

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _state = init

  be apply() =>
    try
      let device = _state("device")? as String
      let channel = _state("channel")? as String
      let auth = _env.root as AmbientAuth
      let monitor = ProcessMonitor(
        auth, auth,
        VolumeClient(this),
        FilePath(auth, "/usr/bin/amixer")?,
        ["amixer"; "-M"; "-D"; device; "get"; channel],
        _env.vars)
      monitor.done_writing()
    else
      _state = _state.update("full_text", "VOL fail")
      _out.receive(_state)
    end

  be receive(data: String val) =>
    let text = recover String(8) end
    text.append("Vol")
    text.append(data)
    _state = _state.update("full_text", consume text)
    _out.receive(_state)


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
      _parent.receive(" fail")
    end
