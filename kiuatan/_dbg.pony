use "debug"
use per = "collections/persistent"

primitive _Dbg[S, V: Any #share]
  fun _dbg(stack: per.List[_LRRecord[S, V]], msg: String) =>
    Debug.out(_dbg_get_indent(stack) + msg)

  fun _dbg_res(result: Result[S, V]): String =>
    match result
    | let success: Success[S, V] =>
      "  => [" + success.start.string() + "," + success.next.string() + ")"
    | let failure: Failure[S, V] =>
      "  => !" + failure.start.string() + ": '" + failure.message + "'"
    end

  fun _dbg_get_indent(stack: per.List[_LRRecord[S, V]]): String =>
    recover
      var len = stack.size() * 2
      let s = String(len)
      while (len = len - 1) > 0 do
        s.push(' ')
      end
      s
    end
