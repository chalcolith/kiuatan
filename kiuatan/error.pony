class val Error[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Will result in an error with the given message.
  """

  let _message: String
  let _action: (Action[S, D, V] | None)

  new create(message: String, action: (Action[S, D, V] | None) = None) =>
    _message = message
    _action = action

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    let result = Failure[S, D, V](this, loc, state.data, _message)
    ifdef debug then
      _Dbg.out(depth, "ERROR " + result.string())
    end
    outer(consume state, result)

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
