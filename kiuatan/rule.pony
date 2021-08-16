use per = "collections/persistent"

class val Rule[S, V: Any #share = None] is RuleNode[S, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """
  let name: String
  var _body: (RuleNode[S, V] box | None)
  let _action: (Action[S, V] | None)

  new create(name': String, body: (RuleNode[S, V] box | None) = None,
    action: (Action[S, V] | None) = None)
  =>
    name = name'
    _body = body
    _action = action

  fun ref set_body(body: RuleNode[S, V] box) =>
    _body = body

  fun eq(other: Rule[S, V]): Bool =>
    this is other

  fun val _is_terminal(stack: per.List[RuleNode[S, V] tag] =
    per.Lists[RuleNode[S, V] tag].empty()): Bool
  =>
    match _body
    | let body: val->RuleNode[S, V] =>
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
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Continuation[S, V])
  =>
    let rule = this
    match _body
    | let body: RuleNode[S, V] =>
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
              cont(Failure[S, V](rule, failure.start, "expected " + rule.name,
                failure), stack', recur')
            end
          }
        end
      parser._parse_with_memo(body, src, loc, stack, recur, consume cont')
    else
      cont(Failure[S, V](this, loc, "rule is empty"), stack, recur)
    end

  fun _get_action(): (Action[S, V] | None) =>
    _action
