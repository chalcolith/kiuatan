use per = "collections/persistent"

class val Conj[S, V: Any #share = None]
  """
  Matches a sequence of child rules.
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
    _parse_one(0, loc, parser, src, loc, stack, recur,
      per.Lists[Success[S, V]].empty(), cont)

  fun val _parse_one(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    children: per.List[Success[S, V]],
    cont: _Continuation[S, V])
  =>
    if child_index == _children.size() then
      cont(Success[S, V](this, start, loc, children.reverse()), stack, recur)
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
                rule._parse_one(child_index + 1, start, parser, src,
                  success.next, stack', recur', children.prepend(success), cont)
              | let failure: Failure[S, V] =>
                cont(Failure[S, V](rule, start, "", failure), stack',
                  recur')
              end
            }
          end

        parser._parse_with_memo(_children(child_index)?, src, loc, stack,
          recur, consume cont')
      else
        cont(Failure[S, V](this, start, "conj failed"), stack, recur)
      end
    end

  fun val _get_action(): (Action[S, V] | None) =>
    _action
