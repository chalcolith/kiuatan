use per = "collections/persistent"

class val Single[S: (Any #read & Equatable[S]), D: Any #share = None,
  V: Any #share = None] is RuleNode[S, D, V]
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

  fun val _is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    try
      if loc.has_value() then
        if _expected.size() > 0 then
          for exp in _expected.values() do
            if exp == loc()? then
              cont(Success[S, D, V](this, loc, loc.next(), data), stack, recur)
              return
            end
          end
        else
          cont(Success[S, D, V](this, loc, loc.next(), data), stack, recur)
          return
        end
      end
    end
    cont(Failure[S, D, V](this, loc, data, "any failed"), stack, recur)

  fun val _get_action(): (Action[S, D, V] | None) =>
    _action
