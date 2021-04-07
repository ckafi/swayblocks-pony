use "files"
use "process"
use "regex"
use "collections"


actor Volume
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
      _state("full_text") = "VOL FAIL"
      _send()
    end

  be receive(data: String val) =>
    _state("full_text") = "Vol" + data
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)


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
