use per = "collections/persistent"

class val Look[S, D: Any #share = None, V: Any #share = None]
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

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "LOOK @" + loc.string())
    end
    let self = this
    _body.parse(parser, depth + 1, loc,
      {(result: Result[S, D, V]) =>
        let result' =
          match result
          | let success: Success[S, D, V] =>
            Success[S, D, V](self, loc, loc, [success])
          | let failure: Failure[S, D, V] =>
            Failure[S, D, V](self, loc, None, failure)
          end
        ifdef debug then
          _Dbg.out(depth, "= " + result'.string())
        end
        outer(result')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
