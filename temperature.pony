use "files"
use "collections"
use "format"


actor Temperature
  let _env: Env
  let _out: OutputActor
  let _init: State val
  var _state: State iso
  var _inputs: (Array[File] | None) = None

  new create(env: Env, out: OutputActor, init: State val) =>
    _env = env
    _out = out
    _init = init
    _state = recover _init.clone() end
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
      _state("full_text") = Format.float[F64](v where fmt = FormatFix, prec = 1)
    else
      _state("full_text") = "Temp fail"
    end
    _send()

  fun ref _send() =>
    _out.receive(_state = recover _init.clone() end)
