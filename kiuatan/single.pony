use per = "collections/persistent"

class val Single[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a single item.  If given a list of possibilities, will only succeed if it matches one of them.  Otherwise, it succeeds for any single item.
  """

  let _expected: ReadSeq[S] val
  let _action: (Action[S, D, V] | None)

  new create(expected: ReadSeq[S] val = [],
    action: (Action[S, D, V] | None) = None)
  =>
    _expected = expected
    _action = action

  fun might_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    false

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "SING @" + loc._dbg(state.source))
    end

    let result = _parse_single(loc, state.data)
    ifdef debug then
      _Dbg.out(depth, "< " + result.string())
    end
    outer(consume state, result)

  fun val _parse_single(loc: Loc[S], data: D): Result[S, D, V] =>
    try
      if loc.has_value() then
        if _expected.size() > 0 then
          for exp in _expected.values() do
            if exp == loc()? then
              return Success[S, D, V](this, loc, loc.next(), data)
            end
          end
          Failure[S, D, V](this, loc, data)
        else
          Success[S, D, V](this, loc, loc.next(), data)
        end
      else
        Failure[S, D, V](this, loc, data)
      end
    else
      Failure[S, D, V](this, loc, data, ErrorMsg.single_failed())
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
