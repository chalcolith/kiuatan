use per = "collections/persistent"

class Neg[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Negative lookahead: will succeed if its child rule does not match, and will not advance the match position.
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
    _Dbg() and _Dbg.out(depth, "NEG  @" + loc.string())
    let self = this
    _body.parse(parser, depth + 1, loc,
      {(result: Result[S, D, V]) =>
        let result' =
          match result
          | let _: Success[S, D, V] =>
            Failure[S, D, V](self, loc)
          | let _: Failure[S, D, V] =>
            Success[S, D, V](self, loc, loc)
          end
        _Dbg() and _Dbg.out(depth, "= " + result'.string())
        outer(result')
      })

  fun action(): (Action[S, D, V] | None) =>
    _action
