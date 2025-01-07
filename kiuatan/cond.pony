class Cond[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let _body: RuleNode[S, D, V]
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(
    body': RuleNode[S, D, V],
    cond': {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _body = body'
    _cond = cond'

  fun action(): (Action[S, D, V] | None) =>
    None

  fun body(): (this->(RuleNode[S, D, V]) | None) =>
    _body

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _CondFrame[S, D, V](this, depth, loc, _body, _cond)

class _CondFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V] box
  let _depth: USize
  let _loc: Loc[S]
  let _body: RuleNode[S, D, V] box
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(
    rule: RuleNode[S, D, V] box,
    depth: USize,
    loc: Loc[S],
    body: RuleNode[S, D, V] box,
    cond: {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _body = body
    _cond = cond

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      (let succeeded, let message) = _cond(success)
      if succeeded then
        _Dbg() and _Dbg.out(_depth, "= " + success.string())
        success
      else
        _Dbg() and _Dbg.out(_depth, "= failure: " + message.string())
        Failure[S, D, V](_rule, success.start, message)
      end
    | let failure: Failure[S, D, V] =>
      _Dbg() and _Dbg.out(_depth, "= " + failure.string())
      failure
    else
      _Dbg() and _Dbg.out(_depth, "COND @" + _loc.string())
      _body.call(_depth + 1, _loc)
    end
