use per = "collections/persistent"

class val NamedRule[S, D: Any #share = None, V: Any #share = None] is RuleNode[S, D, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """
  let name: String
  var _body: (RuleNode[S, D, V] box | None)
  let _action: (Action[S, D, V] | None)

  new create(name': String, body: (RuleNode[S, D, V] box | None) = None,
    action: (Action[S, D, V] | None) = None)
  =>
    name = name'
    _body = body
    _action = action

  fun ref set_body(body: RuleNode[S, D, V] box) =>
    _body = body

  // fun eq(other: RuleNode[S, D, V]): Bool =>
  //   this is other

  fun val _is_terminal(stack: _RuleNodeStack[S, D, V] =
    per.Lists[RuleNode[S, D, V] tag].empty()): Bool
  =>
    match _body
    | let body: val->RuleNode[S, D, V] =>
      let rule = this
      if stack.exists({(x) => x is rule}) then
        false
      else
        body._is_terminal(stack.prepend(rule))
      end
    else
      true
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
    match _body
    | let body: RuleNode[S, D, V] =>
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
              cont(Failure[S, D, V](rule, failure.start, data,
                "expected " + rule.name, failure), stack', recur')
            end
          }
        end
      parser._parse_with_memo(body, src, loc, data, stack, recur, consume cont')
    else
      cont(Failure[S, D, V](this, loc, data, "rule is empty"), stack, recur)
    end

  fun _get_action(): (Action[S, D, V] | None) =>
    _action
