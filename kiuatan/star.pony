use per = "collections/persistent"

class val Star[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

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

  fun val not_recursive(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body.not_recursive(stack.prepend(rule))
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
    index: USize,
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
    parser._parse_with_memo(_body, src, loc, data, stack, recur,
      this~_continue_first(index, start, parser, src, loc, data, children,
        continue_next))

  fun val _continue_first(
    index: USize,
    start: Loc[S],
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    children: per.List[Success[S, D, V]],
    continue_next: _Continuation[S, D, V],
    result: Result[S, D, V],
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V])
  =>
    match result
    | let success: Success[S, D, V] =>
      if index == _max then
        continue_next(Failure[S, D, V](this, start, data,
          ErrorMsg.star_too_long()), stack, recur)
      else
        this._parse_one(index + 1, start, parser, src, success.next, data,
          stack, recur, children.prepend(success), continue_next)
      end
    | let failure: Failure[S, D, V] =>
      if index < _min then
        continue_next(Failure[S, D, V](this, start, data,
          ErrorMsg.star_too_short()), stack, recur)
      else
        continue_next(Success[S, D, V](this, start, loc, data,
          children.reverse()), stack, recur)
      end
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
