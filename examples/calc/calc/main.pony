
actor Main
  new create(env: Env) =>
    env.out.print("Please enter an expression (blank to quit):")
    env.out.write("> ")
    env.input(Notify(env))

class iso Notify
  let env: Env
  let buffer: Array[U8]

  new iso create(env': Env) =>
    env = env'
    buffer = Array[U8]

  fun ref apply(data: Array[U8] iso) =>
    try
      var i: USize = 0
      while i < data.size() do
        let ch = data(i)?
        if (ch == '\n') or (ch == '\r') then
          env.out.print("")
          if buffer.size() > 0 then
            let str = String
            for ch' in buffer.values() do
              str.push(ch')
            end
            env.out.print("'" + str + "'")
            buffer.clear()
            env.out.write("> ")
          else
            env.out.print("Done.")
            env.input.dispose()
            return
          end
        else
          env.out.write([ch])
          buffer.push(ch)
        end
        i = i + 1
      end
    else
      env.out.print("Error")
      env.input.dispose()
    end

  fun ref dispose() =>
    None
