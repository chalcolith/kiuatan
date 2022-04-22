use per = "collections/persistent"

class val Neg[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Negative lookahead: will succeed if its child rule does not match, and will not advance the match position.
  """

  let _body: RuleNode[S, D, V] box
  let _action: (Action[S, D, V] | None)

  new create(body: RuleNode[S, D, V] box,
    action: (Action[S, D, V] | None) = None)
  =>
    _body = body
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
    continue_next: _Continuation[S, D, V])
  =>
    parser._parse_with_memo(_body, src, loc, data, stack, recur,
      this~_continue_first(loc, data, continue_next))

  fun val _continue_first(
    loc: Loc[S],
    data: D,
    continue_next: _Continuation[S, D, V],
    result: Result[S, D, V],
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V])
  =>
    match result
    | let success: Success[S, D, V] =>
      continue_next(Failure[S, D, V](this, loc, data), stack, recur)
    | let failure: Failure[S, D, V] =>
      continue_next(Success[S, D, V](this, loc, loc, data), stack, recur)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
