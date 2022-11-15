use per = "collections/persistent"

class val Neg[S, D: Any #share = None, V: Any #share = None]
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
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "NEG  @" + loc._dbg(state.source))
    end
    let self = this
    _body.parse(consume state, depth + 1, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        let result'' =
          match result'
          | let _: Success[S, D, V] =>
            Failure[S, D, V](self, loc, state'.data)
          | let _: Failure[S, D, V] =>
            Success[S, D, V](self, loc, loc, state'.data)
          end
        ifdef debug then
          _Dbg.out(depth, "= " + result''.string())
        end
        outer(consume state', result'')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
