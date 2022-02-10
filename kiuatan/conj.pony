use per = "collections/persistent"

class val Conj[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a sequence of child rules.
  """

  let _children: ReadSeq[RuleNode[S, D, V] box]
  let _action: (Action[S, D, V] | None)

  new create(children: ReadSeq[RuleNode[S, D, V] box],
    action: (Action[S, D, V] | None) = None)
  =>
    _children = children
    _action = action

  fun val is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      let stack' = stack.prepend(rule)
      for child in _children.values() do
        if not child.is_terminal(stack') then
          return false
        end
      end
      true
    end

  fun val parse(
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    _parse_one(0, loc, parser, src, loc, data, stack, recur,
      per.Lists[Success[S, D, V]].empty(), cont)

  fun val _parse_one(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    children: per.List[Success[S, D, V]],
    continue_next: _Continuation[S, D, V])
  =>
    if child_index == _children.size() then
      continue_next(Success[S, D, V](this, start, loc, data,
        children.reverse()), stack, recur)
    else
      try
        parser._parse_with_memo(_children(child_index)?, src, loc, data, stack,
          recur, this~_continue_first(child_index, start, parser, src, data,
            children, continue_next))
      else
        continue_next(Failure[S, D, V](this, start, data,
          ErrorMsg.conjunction_failed()), stack, recur)
      end
    end

  fun val _continue_first(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, D, V],
    src: Source[S],
    data: D,
    children: per.List[Success[S, D, V]],
    continue_next: _Continuation[S, D, V],
    result: Result[S, D, V],
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V])
  =>
    match result
    | let success: Success[S, D, V] =>
      this._parse_one(child_index + 1, start, parser, src,
        success.next, data, stack, recur, children.prepend(success),
        continue_next)
    | let failure: Failure[S, D, V] =>
      continue_next(Failure[S, D, V](this, start, data, None, failure), stack,
        recur)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
