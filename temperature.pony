use "files"
use "collections"
use "format"


actor Temperature
  let _env: Env
  let _out: OutputActor
  var _inputs: (Array[File] | None) = None

  new create(env: Env, out: OutputActor) =>
    _env = env
    _out = out
    _inputs = Array[File](5)
    try
      var path = FilePath(_env.root as AmbientAuth, "/sys/devices/platform/coretemp.0/hwmon/")?
      path = path.join(Directory(path)?.entries()?(0)?)?
      for f in Directory(path)?.entries()?.values() do
        if f.contains("input") then (_inputs as Array[File]).push(File.open(path.join(f)?)) end
      end
    end

  be apply() =>
    var total: U64 = 0
    try
      let inputs = _inputs as Array[File]
      for f in inputs.values() do
        f.seek_start(0)
        total = total + f.read_string(1024).>rstrip().u64()?
      end
      let v = total.f64()/inputs.size().f64()/1000
      receive(Format.float[F64](v where fmt = FormatFix, prec = 1))
    else
      receive("??")
    end

  be receive(data: String val) =>
    let m = recover Map[String val, String val] end
    m.insert("name", "temperature")
    m.insert("full_text", data + "°C")
    _out.receive(consume m)
