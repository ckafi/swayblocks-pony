use "files"
use "ini"
use "collections/persistent"
use np = "collections"

primitive Config
  fun apply(path: FilePath): Map[String val, State] ? =>
    if not path.exists() then error end
    let config = np.Map[String val, State]
    let lines = File.open(path).lines()

    let f = object
      let config: np.Map[String val, State] = config
      var counter: I64 = 0

      fun ref apply(section: String, key: String, value: String): Bool =>
        try
          if not config.contains(section) then
            add_section(section)
          end
          let s = config(section)?
          config(section) = s.update(key, _parse_value(value))
        end
        true

      fun ref add_section(section: String): Bool =>
        if not config.contains(section) then
          var c = State
          if section != "" then
            c = c.update("name", section.clone())
                 .update("position", counter)
            counter = counter + 1
          end
          config.insert(section, c)
        end
        true

      fun ref errors(line: USize, err: IniError): Bool =>
        false

      fun _parse_value(str: String): (I64 | Bool | String) =>
        try
          match (str, str.at_offset(0)?)
          | ("true", _) => true
          | ("false", _) => false
          | (_, let c: U8) if (c >= '0') and (c <= '9') => str.i64()?
          else error
          end
        else
          str
        end
    end

    if not Ini(lines, f) then
      error
    end

    try
      let default = config.remove("")?._2
      for v in config.values() do
        v.concat(default.pairs())
      end
    end
    Map[String val, State].concat(config.pairs())
