use "debug"
use per = "collections/persistent"

primitive _Dbg[S, D: Any #share, V: Any #share]
  fun _dbg(stack: _LRStack[S, D, V], msg: String) =>
    Debug.out(_dbg_get_indent(stack) + msg)

  fun _dbg_res(result: Result[S, D, V]): String =>
    match result
    | let success: Success[S, D, V] =>
      "  => [" + success.start.string() + "," + success.next.string() + ")"
    | let failure: Failure[S, D, V] =>
      "  => !" + failure.start.string() + ": '" + failure.get_message() + "'"
    end

  fun _dbg_get_indent(stack: _LRStack[S, D, V]): String =>
    recover
      var len = stack.size() * 2
      let s = String(len)
      while (len = len - 1) > 0 do
        s.push(' ')
      end
      s
    end
