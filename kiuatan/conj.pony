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

  fun val _is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
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
    cont: _Continuation[S, D, V])
  =>
    if child_index == _children.size() then
      cont(Success[S, D, V](this, start, loc, data, children.reverse()), stack,
        recur)
    else
      try
        let rule = this
        let cont' =
          recover
            {(result: Result[S, D, V], stack': _LRStack[S, D, V],
              recur': _LRByRule[S, D, V])
            =>
              match result
              | let success: Success[S, D, V] =>
                rule._parse_one(child_index + 1, start, parser, src,
                  success.next, data, stack', recur', children.prepend(success),
                  cont)
              | let failure: Failure[S, D, V] =>
                cont(Failure[S, D, V](rule, start, data, "", failure), stack',
                  recur')
              end
            }
          end

        parser._parse_with_memo(_children(child_index)?, src, loc, data, stack,
          recur, consume cont')
      else
        cont(Failure[S, D, V](this, start, data, "conj failed"), stack, recur)
      end
    end

  fun val _get_action(): (Action[S, D, V] | None) =>
    _action
