class val Literal[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a string of items.
  """

  let _expected: ReadSeq[S] val
  let _action: (Action[S, D, V] | None)

  new create(expected: ReadSeq[S] val, action: (Action[S, D, V] | None) = None)
  =>
    _expected = expected
    _action = action

  fun val cant_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    true

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "LIT  @" + loc._dbg(state.source))
    end

    let result =
      try
        var act = loc
        for exp in _expected.values() do
          if (not act.has_value()) or (exp != act()?) then
            break Failure[S, D, V](this, loc, state.data)
          end
          act = act.next()
          Success[S, D, V](this, loc, act, state.data)
        else
          Success[S, D, V](this, loc, loc, state.data)
        end
      else
        Failure[S, D, V](this, loc, state.data, ErrorMsg.literal_failed())
      end
    ifdef debug then
      _Dbg.out(depth, "< " + result.string())
    end
    outer(consume state, result)

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
