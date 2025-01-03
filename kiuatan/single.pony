class Single[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a single item.  If given a list of possibilities, will only succeed if it matches one of them.  Otherwise, it succeeds for any single item.
  """

  let _expected: ReadSeq[S] val
  let _action: (Action[S, D, V] | None)

  new create(
    expected': ReadSeq[S] val = [],
    action': (Action[S, D, V] | None) = None)
  =>
    _expected = expected'
    _action = action'

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _SingleFrame[S, D, V](this, depth, loc, _expected)

class _SingleFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _expected: ReadSeq[S] val

  new create(
    rule: RuleNode[S, D, V],
    depth: USize,
    loc: Loc[S],
    expected: ReadSeq[S] val)
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _expected = expected

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    let result =
      try
        if _loc.has_value() then
          if _expected.size() > 0 then
            for exp in _expected.values() do
              if exp == _loc()? then
                return Success[S, D, V](_rule, _loc, _loc.next())
              end
            end
            Failure[S, D, V](_rule, _loc)
          else
            Success[S, D, V](_rule, _loc, _loc.next())
          end
        else
          Failure[S, D, V](_rule, _loc)
        end
      else
        Failure[S, D, V](_rule, _loc, ErrorMsg.single_failed())
      end
    _Dbg() and _Dbg.out(
      _depth, "SING @" + _loc.string() + " = " + result.string())
    result
