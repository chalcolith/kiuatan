use per = "collections/persistent"

class val Bind[S, V: Any #share = None]
  let variable: Variable
  let _body: RuleNode[S, V] box

  new create(variable': Variable, body: RuleNode[S, V] box) =>
    variable = variable'
    _body = body

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
            cont(Success[S, V](rule, success.start, success.next, [success]),
              stack', recur')
          | let failure: Failure[S, V] =>
            cont(Failure[S, V](rule, failure.start, failure.message, failure),
              stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): (Action[S, V] | None) =>
    None
