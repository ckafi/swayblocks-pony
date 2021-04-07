use "time"
use "process"
use "files"
use "collections"
use "json"

actor Main
  let second: U64 = 1_000_000_000
  let _env: Env

  new create(env: Env) =>
    _env = env
    let config = try
      recover val Config(_default_conifg_path()?)? end
    else
      _env.err.print("Failed to open config")
      return
    end
    let out = Output(env)
    let timers = Timers
    for (k,v) in config.pairs() do
      try
        let s = (v("interval")? as I64).u64()
        let m = _get_module(k, out, v)?
        timers(Timer(ActorNotify(m), 0, s*second))
      else
      _env.err.print("Error spawning module " + k)
      end
    end
    timers(Timer(ActorNotify(out), 0, second))

  fun _default_conifg_path(): FilePath ? =>
    var config_path_s = ""
    for v in _env.vars.values() do
      if v.contains("XDG_CONFIG_HOME=") then
        config_path_s = v.split_by("=")(1)?
        break
      end
    end
    FilePath(
      _env.root as AmbientAuth,
          config_path_s)?
    .join("swayblocks-pony")?

  fun _get_module(
    name: String,
    out: OutputActor,
    init: State val)
  : TimeableActor ?
  =>
    match name.split_by(":")(0)?
    | "Volume" => Volume(_env, out, init)
    | "CPU" => CPU(_env, out, init)
    | "Load" => Load(_env, out, init)
    | "Temperature" => Temperature(_env, out, init)
    | "Date" => Date(_env, out, init)
    | "Fuzzytime" => Fuzzytime(_env, out, init)
    | "Memory" => Memory(_env, out, init)
    | "Bandwith" => Bandwith(_env, out, init)
    else
      error
    end


interface tag TimeableActor
  be apply()


class ActorNotify is TimerNotify
  let _actor: TimeableActor

  new iso create(actor': TimeableActor tag) =>
    _actor = actor'

  fun ref apply(timer: Timer ref, count: U64 val): Bool val =>
    _actor()
    true


type State is Map[String val, (I64 | Bool | String val)]
