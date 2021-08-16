use per = "collections/persistent"

class val Disj[S, V: Any #share = None]
  """
  Matches one out of a list of possible alternatives.  Tries each alternative in
  order.  If one alternative fails, but an outer rule later fails, will *not*
  backtrack to another alternative.
  """
  let _children: ReadSeq[RuleNode[S, V] box]
  let _action: (Action[S, V] | None)

  new create(children: ReadSeq[RuleNode[S, V] box],
    action: (Action[S, V] | None) = None)
  =>
    _children = children
    _action = action

  fun val _is_terminal(stack: per.List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      let stack' = stack.prepend(rule)
      for child in _children.values() do
        if not child._is_terminal(stack') then
          return false
        end
      end
      true
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Continuation[S, V])
  =>
    _parse_one(0, loc, parser, src, loc, stack, recur, cont)

  fun val _parse_one(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Continuation[S, V])
  =>
    if child_index == _children.size() then
      cont(Failure[S, V](this, start), stack, recur)
    else
      try
        let rule = this
        let cont' =
          recover
            {(result: Result[S, V], stack': per.List[_LRRecord[S, V]],
              recur': _LRByRule[S, V])
            =>
              match result
              | let success: Success[S, V] =>
                cont(Success[S, V](rule, start, success.next, [success]),
                  stack', recur')
              | let failure: Failure[S, V] =>
                rule._parse_one(child_index + 1, start, parser, src,
                  start, stack', recur', cont)
              end
            }
          end

        parser._parse_with_memo(_children(child_index)?, src, start, stack,
          recur, consume cont')
      else
        cont(Failure[S, V](this, start, "disj failed"), stack, recur)
      end
    end

  fun val _get_action(): (Action[S, V] | None) =>
    _action
