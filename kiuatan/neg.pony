class Neg[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Negative lookahead: will succeed if its child rule does not match, and will not advance the match position.
  """

  let _body: RuleNode[S, D, V]
  let _action: (Action[S, D, V] | None)

  new create(
    body': RuleNode[S, D, V],
    action': (Action[S, D, V] | None) = None)
  =>
    _body = body'
    _action = action'

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun body(): (this->(RuleNode[S, D, V]) | None) =>
    _body

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _NegFrame[S, D, V](this, depth, loc, _body)

class _NegFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _body: RuleNode[S, D, V]

  new create(
    rule: RuleNode[S, D, V],
    depth: USize,
    loc: Loc[S],
    body: RuleNode[S, D, V])
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _body = body

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      let result = Failure[S, D, V](_rule, _loc)
      _Dbg() and _Dbg.out(_depth, "= " + result.string())
      result
    | let failure: Failure[S, D, V] =>
      let result = Success[S, D, V](_rule, _loc, _loc)
      _Dbg() and _Dbg.out(_depth, "= " + result.string())
      result
    else
      _Dbg() and _Dbg.out(_depth, "NEG  @" + _loc.string())
      _body.call(_depth + 1, _loc)
    end
