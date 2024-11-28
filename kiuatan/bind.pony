use per = "collections/persistent"

class Bind[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let variable: Variable
  let _body: RuleNode[S, D, V] box

  new create(
    variable': Variable,
    body': RuleNode[S, D, V] box)
  =>
    variable = variable'
    _body = body'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    _Dbg() and _Dbg.out(depth,"BIND " + variable.name + " @" + loc.string())

    let result =
      match _body.parse(parser, depth + 1, loc)
      | let success: Success[S, D, V] =>
        Success[S, D, V](this, success.start, success.next, [success])
      | let failure: Failure[S, D, V] =>
        failure
      end
    _Dbg() and _Dbg.out(
      depth, "     = " + variable.name + " := " + result.string())
    result

  fun action(): (Action[S, D, V] | None) =>
    None
