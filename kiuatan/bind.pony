class Bind[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let variable: Variable
  let _body: RuleNode[S, D, V]

  new create(
    variable': Variable,
    body': RuleNode[S, D, V])
  =>
    variable = variable'
    _body = body'

  fun action(): (Action[S, D, V] | None) =>
    None

  fun body(): (this->(RuleNode[S, D, V]) | None) =>
    _body

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _BindFrame[S, D, V](this, depth, loc, variable.name, _body)

class _BindFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _name: String
  let _body: RuleNode[S, D, V]

  new create(
    rule: RuleNode[S, D, V],
    depth: USize,
    loc: Loc[S],
    name: String,
    body: RuleNode[S, D, V])
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _name = name
    _body = body

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      _Dbg() and _Dbg.out(_depth, "= " + _name + " := " + success.string())
      Success[S, D, V](_rule, success.start, success.next, [ success ])
    | let failure: Failure[S, D, V] =>
      _Dbg() and _Dbg.out(_depth, "= " + _name + " := " + failure.string())
      failure
    else
      _Dbg() and _Dbg.out(_depth, "BIND " + _name + " @" + _loc.string())
      _body.call(_depth + 1, _loc)
    end
