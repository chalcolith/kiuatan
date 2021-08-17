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
            cont(Failure[S, D, V](rule, loc, data, "neg failed"), stack',
              recur')
          | let failure: Failure[S, D, V] =>
            cont(Success[S, D, V](rule, loc, loc, data), stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, data, stack, recur, consume cont')

  fun val _get_action(): (Action[S, D, V] | None) =>
    _action
