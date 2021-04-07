use "json"
use "collections"


actor Output
  let _env: Env
  var _state: Array[State val] = Array[State val]
  let _dummy: State val

  new create(env: Env) =>
    _env = env
    _dummy = recover val State.>insert("full_text", "") end
    _env.out.print("{\"version\":1,\"click_events\":true}")
    _env.out.print("[[]")

  be apply() =>
    let out = recover String end
    out.append(",")
    let j = JsonArray
    for v in _state.values() do
      let obj = JsonObject
      obj.data.concat(v.pairs())
      j.data.push(obj)
    end
    out.append(j.string())
    _env.out.print(consume out)

  be receive(data: State val) =>
    try
      let n = (data("position")? as I64).usize()
      while _state.size() <= n do
        _state.push(_dummy)
      end
      _state(n)? = data
    end

interface tag OutputActor
  be receive(data: State val)
