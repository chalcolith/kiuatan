use per = "collections/persistent"

class Cond[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let _body: RuleNode[S, D, V] box
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(
    body': RuleNode[S, D, V] box,
    cond': {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _body = body'
    _cond = cond'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    ifdef debug then
      _Dbg.out(depth, "COND @" + loc.string())
    end
    let result =
      match _body.parse(parser, depth + 1, loc)
      | let success: Success[S, D, V] =>
        (let succeeded, let message) = _cond(success)
        if succeeded then
          success
        else
          Failure[S, D, V](this, success.start, message)
        end
      | let failure: Failure[S, D, V] =>
        failure
      end
    ifdef debug then
      _Dbg.out(depth, "     = " + result.string())
    end
    result

  fun action(): (Action[S, D, V] | None) =>
    None
