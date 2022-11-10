use per = "collections/persistent"

class val Cond[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

  let _body: RuleNode[S, D, V] box
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(
    body: RuleNode[S, D, V] box,
    cond: {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _body = body
    _cond = cond

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
      _Dbg.out(depth, "COND @" + loc._dbg(state.source))
    end
    let self = this
    _body.parse(consume state, depth + 1, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        let result'' =
          match result'
          | let success: Success[S, D, V] =>
            (let succeeded: Bool, let message: (String | None)) = _cond(success)
            if succeeded then
              success
            else
              Failure[S, D, V](self, success.start, state'.data, message)
            end
          | let failure: Failure[S, D, V] =>
            failure
          end
        ifdef debug then
          _Dbg.out(depth, "< " + result''.string())
        end
        outer(consume state', result'')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    None
