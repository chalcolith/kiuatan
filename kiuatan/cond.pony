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
    let rule = this
    let cont' =
      recover
        {(result: Result[S, D, V], stack': _LRStack[S, D, V],
          recur': _LRByRule[S, D, V])
        =>
          match result
          | let success: Success[S, D, V] =>
            (let succeeded: Bool, let msg: (String | None)) = _cond(success)
            if succeeded then
              cont(Success[S, D, V](rule, success.start, success.next, data,
                [success]), stack', recur')
            else
              let failure =
                match msg
                | let msg': String =>
                  Failure[S, D, V](rule, success.start, data, msg')
                else
                  Failure[S, D, V](rule, success.start, data,
                    "condition failed")
                end
              cont(failure, stack', recur')
            end
          | let failure: Failure[S, D, V] =>
            cont(failure, stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, data, stack, recur, consume cont')

  fun val _get_action(): (Action[S, D, V] | None) =>
    None
