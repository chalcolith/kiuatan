use per = "collections/persistent"

class val Bind[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

  let variable: Variable
  let _body: RuleNode[S, D, V] box

  new create(variable': Variable, body: RuleNode[S, D, V] box) =>
    variable = variable'
    _body = body

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
            cont(Success[S, D, V](rule, success.start, success.next, data,
              [success]), stack', recur')
          | let failure: Failure[S, D, V] =>
            cont(Failure[S, D, V](rule, failure.start, data, failure.message,
              failure), stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, data, stack, recur, consume cont')

  fun val _get_action(): (Action[S, D, V] | None) =>
    None
