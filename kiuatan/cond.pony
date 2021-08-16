use per = "collections/persistent"

class val Cond[S, V: Any #share = None]
  let _body: RuleNode[S, V] box
  let _cond: {(Success[S, V]): (Bool, (String | None))} val

  new create(body: RuleNode[S, V] box,
    cond: {(Success[S, V]): (Bool, (String | None))} val)
  =>
    _body = body
    _cond = cond

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
    let rule = this
    let cont' =
      recover
        {(result: Result[S, V], stack': per.List[_LRRecord[S, V]],
          recur': _LRByRule[S, V])
        =>
          match result
          | let success: Success[S, V] =>
            (let succeeded: Bool, let msg: (String | None)) = _cond(success)
            if succeeded then
              cont(Success[S, V](rule, success.start, success.next, [success]),
                stack', recur')
            else
              let failure =
                match msg
                | let msg': String =>
                  Failure[S, V](rule, success.start, msg')
                else
                  Failure[S, V](rule, success.start, "condition failed")
                end
              cont(failure, stack', recur')
            end
          | let failure: Failure[S, V] =>
            cont(failure, stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): (Action[S, V] | None) =>
    None
