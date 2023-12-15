use "debug"
use "collections"

primitive _Dbg
  fun out(depth: USize, msg: String) =>
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
    None
