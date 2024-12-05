class Literal[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a string of items.
  """

  let _expected: ReadSeq[S] val
  let _action: (Action[S, D, V] | None)

  new create(
    expected': ReadSeq[S] val,
    action': (Action[S, D, V] | None) = None)
  =>
    _expected = expected'
    _action = action'

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    _Dbg() and _Dbg.out(depth, "LIT @" + loc.string())
    let result =
      try
        var act = loc
        for exp in _expected.values() do
          if (not act.has_value()) or (exp != act()?) then
            break Failure[S, D, V](this, loc, ErrorMsg.literal_unexpected())
          end
          act = act.next()
          Success[S, D, V](this, loc, act)
        else
          Success[S, D, V](this, loc, loc)
        end
      else
        Failure[S, D, V](this, loc, ErrorMsg.literal_failed())
      end
    _Dbg() and _Dbg.out(depth, "= " + result.string())
    outer(result)

  fun action(): (Action[S, D, V] | None) =>
    _action
