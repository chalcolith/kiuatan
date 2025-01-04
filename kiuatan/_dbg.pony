use "debug"
use "collections"

primitive _Dbg
  fun apply(): Bool =>
    // // Uncomment to get lots of debug output
    // ifdef debug then
    //   return true
    // end
    false

  fun out(depth: USize, msg: String): Bool =>
    ifdef debug then
      let indent =
        recover val
          let indent' = String(depth * 2)
          for i in Range(0, depth * 2) do
            indent'.push(' ')
          end
          indent'
        end
      Debug.out(indent + msg)
    end
    false
