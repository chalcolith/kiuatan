use per = "collections/persistent"

class val Look[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Positive lookahead: will succeed if its child rule matches, but will not advance the match position.
  """

  let _body: RuleNode[S, D, V] box
  let _action: (Action[S, D, V] | None)

  new create(
    body: RuleNode[S, D, V] box,
    action: (Action[S, D, V] | None) = None)
  =>
    _body = body
    _action = action

  fun val cant_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body.cant_recurse(stack.prepend(rule))
    end

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "LOOK @" + loc._dbg(state.source))
    end
    let self = this
    _body.parse(consume state, depth + 1, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        let result'' =
          match result'
          | let success: Success[S, D, V] =>
            Success[S, D, V](self, loc, loc, state'.data, [success])
          | let failure: Failure[S, D, V] =>
            Failure[S, D, V](self, loc, state'.data, None, failure)
          end
        ifdef debug then
          _Dbg.out(depth, "< " + result''.string())
        end
        outer(consume state', result'')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
