use per = "collections/persistent"

class val Literal[S: (Any #read & Equatable[S]), V: Any #share = None]
  """
  Matches a string of items.
  """
  let _expected: ReadSeq[S] val
  let _action: (Action[S, V] | None)

  new create(expected: ReadSeq[S] val, action: (Action[S, V] | None) = None) =>
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
      var act = loc
      for exp in _expected.values() do
        if (not act.has_value()) or (exp != act()?) then
          cont(Failure[S, V](this, loc), stack, recur)
          return
        end
        act = act.next()
      end
      cont(Success[S, V](this, loc, act), stack, recur)
    else
      cont(Failure[S, V](this, loc, "literal failed"), stack, recur)
    end

  fun val _get_action(): (Action[S, V] | None) =>
    _action
