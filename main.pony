use "time"
use "process"
use "files"
use "ini"

actor Main
  let second: U64 = 1_000_000_000
  let _env: Env

  new create(env: Env) =>
    _env = env
    let config = try
      _get_config()?
    else
      _env.err.print("Failed to open config")
      return
    end

    let out = Output(env)
    let timers = Timers
    for module_name in config.keys() do
    try
      _add_module(module_name, out, config, timers)?
    else
      _env.err.print("Error spawning module " + module_name)
    end
    end
    timers(Timer(ActorNotify(out), 0, 1*second))

  fun _get_config(): Config ? =>
    recover
      var config_path_s = ""
      for v in _env.vars.values() do
        if v.contains("XDG_CONFIG_HOME=") then
          config_path_s = v.split_by("=")(1)?
          break
        end
      end
      let config_file = File.open(
        FilePath(_env.root as AmbientAuth, config_path_s)?
        .join("swayblocks-pony")?)
      if not config_file.path.exists() then error end
      IniParse(config_file.lines())?
    end

  fun _add_module(
    module_name: String,
    out: OutputActor,
    config: Config,
    timers: Timers)
  : None ?
  =>
    let interval = config(module_name)?("interval")?.u64()?
    // Ugly af, but I don't have a better idea
    // Partial function application crashed ponyc
    let a = match module_name
    | "CPU" => CPU(_env, out, config)
    | "Volume" => Volume(_env, out, config)
    else
      error
    end
    let timer = Timer(ActorNotify(a), 0, interval * second)
    timers(consume timer)
    /*   (Memory(env, out, Mem), 1) */
    /*   (Memory(env, out, Swap), 1) */
    /*   (Bandwith(env, out, "enp0s25", In, 3), 3) */
    /*   (Bandwith(env, out, "enp0s25", Out, 3), 3) */
    /*   (Temperature(env, out), 1) */
    /*   (Load(env, out), 1) */
    /*   (Date(env, out, "%a %d. %b"), 1) */
    /*   (Fuzzytime(env, out), 1) */


interface tag TimeableActor
  be apply()


class ActorNotify is TimerNotify
  let _actor: TimeableActor

  new iso create(actor': TimeableActor tag) =>
    _actor = actor'

  fun ref apply(timer: Timer ref, count: U64 val): Bool val =>
    _actor()
    true


type Config is IniMap val
