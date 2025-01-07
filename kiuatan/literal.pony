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

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _LiteralFrame[S, D, V](this, depth, loc, _expected)

class _LiteralFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V] box
  let _depth: USize
  let _loc: Loc[S]
  let _expected: ReadSeq[S] val

  new create(
    rule: RuleNode[S, D, V] box,
    depth: USize,
    loc: Loc[S],
    expected: ReadSeq[S] val)
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _expected = expected

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    _Dbg() and _Dbg.out(_depth, "LIT @" + _loc.string())
    let result =
      try
        var act = _loc
        for exp in _expected.values() do
          if (not act.has_value()) or (exp != act()?) then
            break Failure[S, D, V](_rule, _loc, ErrorMsg.literal_unexpected())
          end
          act = act.next()
          Success[S, D, V](_rule, _loc, act)
        else
          Success[S, D, V](_rule, _loc, _loc)
        end
      else
        Failure[S, D, V](_rule, _loc, ErrorMsg.literal_failed())
      end
    _Dbg() and _Dbg.out(_depth, "= " + result.string())
    result
