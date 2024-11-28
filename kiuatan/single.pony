use per = "collections/persistent"

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

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    _Dbg() and _Dbg.out(depth, "SING @" + loc.string())

    let result = _parse_single(loc)
    _Dbg() and _Dbg.out(depth, "= " + result.string())
    outer(result)

  fun val _parse_single(loc: Loc[S]): Result[S, D, V] =>
    try
      if loc.has_value() then
        if _expected.size() > 0 then
          for exp in _expected.values() do
            if exp == loc()? then
              return Success[S, D, V](this, loc, loc.next())
            end
          end
          Failure[S, D, V](this, loc)
        else
          Success[S, D, V](this, loc, loc.next())
        end
      else
        Failure[S, D, V](this, loc)
      end
    else
      Failure[S, D, V](this, loc, ErrorMsg.single_failed())
    end

  fun action(): (Action[S, D, V] | None) =>
    _action
