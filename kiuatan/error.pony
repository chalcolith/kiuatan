class Error[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Will result in an error with the given message.
  """

  let _message: String
  let _action: (Action[S, D, V] | None)

  new create(
    message': String,
    action': (Action[S, D, V] | None) = None)
  =>
    _message = message'
    _action = action'

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _ErrorFrame[S, D, V](this, depth, loc, _message)

class _ErrorFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _message: String

  new create(
    rule: RuleNode[S, D, V],
    depth: USize,
    loc: Loc[S],
    message: String)
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _message = message

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    let result = Failure[S, D, V](_rule, _loc, _message, None, true)
    _Dbg() and _Dbg.out(_depth, "ERROR " + result.string())
    result
