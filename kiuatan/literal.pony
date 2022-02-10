use per = "collections/persistent"

class val Literal[S: (Any #read & Equatable[S]), D: Any #share = None,
  V: Any #share = None] is RuleNode[S, D, V]
  """
  Matches a string of items.
  """

  let _expected: ReadSeq[S] val
  let _action: (Action[S, D, V] | None)

  new create(expected: ReadSeq[S] val, action: (Action[S, D, V] | None) = None)
  =>
    _expected = expected
    _action = action

  fun val is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    true

  fun val parse(
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    continue_next: _Continuation[S, D, V])
  =>
    try
      var act = loc
      for exp in _expected.values() do
        if (not act.has_value()) or (exp != act()?) then
          continue_next(Failure[S, D, V](this, loc, data), stack, recur)
          return
        end
        act = act.next()
      end
      continue_next(Success[S, D, V](this, loc, act, data), stack, recur)
    else
      continue_next(Failure[S, D, V](this, loc, data,
        ErrorMsg.literal_failed()), stack, recur)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
