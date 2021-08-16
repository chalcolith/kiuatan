use per = "collections/persistent"

class val Single[S: (Any #read & Equatable[S]), V: Any #share = None]
  """
  Matches a single item.  If given a list of possibilities, will only succeed if it matches one of them.  Otherwise, it succeeds for any single item.
  """
  let _expected: ReadSeq[S] val
  let _action: (Action[S, V] | None)

  new create(expected: ReadSeq[S] val = [],
    action: (Action[S, V] | None) = None)
  =>
    _expected = expected
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
    try
      if loc.has_value() then
        if _expected.size() > 0 then
          for exp in _expected.values() do
            if exp == loc()? then
              cont(Success[S, V](this, loc, loc.next()), stack, recur)
              return
            end
          end
        else
          cont(Success[S, V](this, loc, loc.next()), stack, recur)
          return
        end
      end
    end
    cont(Failure[S, V](this, loc, "any failed"), stack, recur)

  fun val _get_action(): (Action[S, V] | None) =>
    _action
