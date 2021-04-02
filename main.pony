use "time"
use "process"

actor Main
  let second: U64 = 1_000_000_000

  new create(env: Env) =>
    let out = Output(env)

    let actors: Array[(TimeableActor, U64)] = [
      (out, 1)
      (Volume(env, out, "pulse", "Master"), 1)
      (Memory(env, out, Mem), 1)
      (Memory(env, out, Swap), 1)
      (Bandwith(env, out, "enp0s25", In, 3), 3)
      (Bandwith(env, out, "enp0s25", Out, 3), 3)
      (CPU(env, out), 1)
      (Temperature(env, out), 1)
      (Load(env, out), 1)
      (Date(env, out, "%a %d. %b"), 1)
      (Fuzzytime(env, out), 1)
    ]

    let timers = Timers
    for (a, s) in actors.values() do
      let timer = Timer(ActorNotify(a), 0, s * second)
      timers(consume timer)
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
