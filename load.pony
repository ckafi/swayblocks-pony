use "files"
use "collections"


actor Load
  let _env: Env
  let _out: OutputActor
  var _file: (File | None) = None

  new create(env: Env, out: OutputActor) =>
    _env = env
    _out = out
    try
      _file = File.open(FilePath(_env.root as AmbientAuth, "/proc/loadavg")?)
    end

  be apply() =>
    try
      let file = (_file as File).>seek_start(0)
      receive(file.read_string(1024).split()(0)?) // file.size() doesn't work for /proc/
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", "loadavg")
    m.insert("full_text", data)
    _out.receive(consume m)
