use per = "collections/persistent"

class val Star[S, V: Any #share = None]
  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, V] box
  let _min: USize
  let _max: USize
  let _action: (Action[S, V] | None)

  new create(body: RuleNode[S, V] box, min: USize = 0,
    action: (Action[S, V] | None) = None, max: USize = USize.max_value())
  =>
    _body = body
    _min = min
    _max = max
    _action = action

  fun val _is_terminal(stack: per.List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body._is_terminal(stack.prepend(rule))
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
    index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    children: per.List[Success[S, V]],
    cont: _Continuation[S, V])
  =>
    let rule = this
    let cont' =
      recover
        {(result: Result[S, V], stack': per.List[_LRRecord[S, V]],
          recur': _LRByRule[S, V])
        =>
          match result
          | let success: Success[S, V] =>
            if index == _max then
              cont(Failure[S, V](rule, start, "star succeeded too often"),
                stack', recur')
            else
              rule._parse_one(index + 1, start, parser, src,
                success.next, stack', recur', children.prepend(success), cont)
            end
          | let failure: Failure[S, V] =>
            if index >= _min then
              cont(Success[S, V](rule, start, loc, children.reverse()), stack',
                recur')
            else
              cont(Failure[S, V](rule, start,
                "star did not match enough times"), stack', recur')
            end
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): (Action[S, V] | None) =>
    _action
