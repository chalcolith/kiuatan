use per = "collections/persistent"

class val Star[S, D: Any #share = None, V: Any #share = None]
  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, D, V] box
  let _min: USize
  let _max: USize
  let _action: (Action[S, D, V] | None)

  new create(body: RuleNode[S, D, V] box, min: USize = 0,
    action: (Action[S, D, V] | None) = None, max: USize = USize.max_value())
  =>
    _body = body
    _min = min
    _max = max
    _action = action

  fun val _is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body._is_terminal(stack.prepend(rule))
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
    index: USize,
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
    let rule = this
    let cont' =
      recover
        {(result: Result[S, D, V], stack': _LRStack[S, D, V],
          recur': _LRByRule[S, D, V])
        =>
          match result
          | let success: Success[S, D, V] =>
            if index == _max then
              cont(Failure[S, D, V](rule, start, data,
                "star succeeded too often"), stack', recur')
            else
              rule._parse_one(index + 1, start, parser, src, success.next, data,
                stack', recur', children.prepend(success), cont)
            end
          | let failure: Failure[S, D, V] =>
            if index >= _min then
              cont(Success[S, D, V](rule, start, loc, data, children.reverse()),
                stack', recur')
            else
              cont(Failure[S, D, V](rule, start, data,
                "star did not match enough times"), stack', recur')
            end
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, data, stack, recur, consume cont')

  fun val _get_action(): (Action[S, D, V] | None) =>
    _action
