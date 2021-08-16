use per = "collections/persistent"

class val Error[S, V: Any #share = None]
  """
  Will result in an error with the given message.
  """
  let _message: String
  let _action: (Action[S, V] | None)

  new create(message: String, action: (Action[S, V] | None) = None) =>
    _message = message
    _action = action

  fun val _is_terminal(stack: per.List[RuleNode[S, V] tag]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Continuation[S, V])
  =>
    cont(Failure[S, V](this, loc, _message), stack, recur)

  fun val _get_action(): (Action[S, V] | None) =>
    _action
