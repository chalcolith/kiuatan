use "debug"
use "collections"

primitive _Dbg
  fun apply(): Bool =>
    false
    // ifdef debug then
    //   true
    // else
    //   false
    // end

  fun out(depth: USize, msg: String): Bool =>
    // // Uncomment to get lots of debug output
    // let indent =
    //   recover val
    //     let indent' = String(depth * 2)
    //     for i in Range(0, depth * 2) do
    //       indent'.push(' ')
    //     end
    //     indent'
    //   end
    // Debug.out(indent + msg)
    false
