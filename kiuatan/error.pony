use per = "collections/persistent"

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

  fun val _is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    continue_next: _Continuation[S, D, V])
  =>
    continue_next(Failure[S, D, V](this, loc, data, _message), stack, recur)

  fun val _get_action(): (Action[S, D, V] | None) =>
    _action
