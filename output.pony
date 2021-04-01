use "json"
use "collections"
use "format"

use "debug"

actor Output
  let _env: Env
  let _state: Map[String val, JsonType]

  new create(env: Env) =>
    _env = env
    _state = Map[String val, JsonType]
    _env.out.print("{\"version\":1,\"click_events\":true}")
    _env.out.print("[[]")

  be apply() =>
    let j = JsonArray(_state.size())
    for e in _state.values() do
      j.data.push(e)
    end
    let out = recover String end
    out.append(",")
    out.append(j.string())
    _env.out.print(consume out)

  be receive(data: Map[String val, String val] iso) =>
    try
      let name = data("name")?
      let j = JsonObject
      j.data.concat((consume data).pairs())
      _state(name) = consume j
    end


interface tag OutputActor
  be receive(data: Map[String val, String val] iso)
