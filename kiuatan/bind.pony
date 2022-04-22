use per = "collections/persistent"

class val Bind[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

  let variable: Variable
  let _body: RuleNode[S, D, V] box

  new create(variable': Variable, body: RuleNode[S, D, V] box) =>
    variable = variable'
    _body = body

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
      this~_continue_first(data, continue_next))

  fun val _continue_first(data: D, continue_next: _Continuation[S, D, V],
    result: Result[S, D, V], stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V])
  =>
    match result
    | let success: Success[S, D, V] =>
      continue_next(Success[S, D, V](this, success.start, success.next, data,
        [success]), stack, recur)
    | let failure: Failure[S, D, V] =>
      continue_next(Failure[S, D, V](this, failure.start, data, None, failure),
        stack, recur)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    None
