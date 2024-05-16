use per = "collections/persistent"

class Look[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Positive lookahead: will succeed if its child rule matches, but will not advance the match position.
  """

  let _body: RuleNode[S, D, V] box
  let _action: (Action[S, D, V] | None)

  new create(
    body': RuleNode[S, D, V] box,
    action': (Action[S, D, V] | None) = None)
  =>
    _body = body'
    _action = action'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    ifdef debug then
      _Dbg.out(depth, "LOOK @" + loc.string())
    end

    let result =
      match _body.parse(parser, depth + 1, loc)
      | let _: Success[S, D, V] =>
        Success[S, D, V](this, loc, loc)
      | let failure: Failure[S, D, V] =>
        Failure[S, D, V](this, loc, "lookahead failed", failure)
      end
    ifdef debug then
      _Dbg.out(depth, "= " + result.string())
    end
    result

  fun action(): (Action[S, D, V] | None) =>
    _action
