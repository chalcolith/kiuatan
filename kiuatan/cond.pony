use per = "collections/persistent"

class val Cond[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

  let _body: RuleNode[S, D, V] box
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(body: RuleNode[S, D, V] box,
    cond: {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _body = body
    _cond = cond

  fun val is_terminal(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body.is_terminal(stack.prepend(rule))
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
      (let succeeded: Bool, let msg: (String | None)) = _cond(success)
      if succeeded then
        continue_next(Success[S, D, V](this, success.start, success.next, data,
          [success]), stack, recur)
      else
        let message = try msg as String else ErrorMsg.condition_failed() end
        continue_next(Failure[S, D, V](this, success.start, data, message),
          stack, recur)
      end
    | let failure: Failure[S, D, V] =>
      continue_next(Failure[S, D, V](this, failure.start, data, None, failure),
        stack, recur)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    None
