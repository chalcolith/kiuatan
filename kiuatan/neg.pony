use per = "collections/persistent"

class val Neg[S, V: Any #share = None]
  """
  Negative lookahead: will succeed if its child rule does not match, and will not advance the match position.
  """
  let _body: RuleNode[S, V] box
  let _action: (Action[S, V] | None)

  new create(body: RuleNode[S, V] box, action: (Action[S, V] | None) = None) =>
    _body = body
    _action = action

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
            cont(Failure[S, V](rule, loc, "neg failed"), stack', recur')
          | let failure: Failure[S, V] =>
            cont(Success[S, V](rule, loc, loc), stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): (Action[S, V] | None) =>
    _action
