class Error[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Will result in an error with the given message.
  """

  let _message: String
  let _action: (Action[S, D, V] | None)

  new create(
    message': String,
    action': (Action[S, D, V] | None) = None)
  =>
    _message = message'
    _action = action'

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    let result = Failure[S, D, V](this, loc, _message)
    _Dbg() and _Dbg.out(depth, "ERROR " + result.string())
    result

  fun action(): (Action[S, D, V] | None) =>
    _action
