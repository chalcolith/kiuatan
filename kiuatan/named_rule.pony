use per = "collections/persistent"

class val NamedRule[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """

  let name: String
  var _body: (RuleNode[S, D, V] box | None)
  var _action: (Action[S, D, V] | None)

  new create(name': String, body': (RuleNode[S, D, V] box | None) = None,
    action': (Action[S, D, V] | None) = None)
  =>
    name = name'
    _body = body'
    _action = action'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun has_body(): Bool =>
    _body isnt None

  fun ref set_body(
    body': RuleNode[S, D, V] box,
    action': (Action[S, D, V] | None) = None)
  =>
    _body = body'
    if action' isnt None then
      _action = action'
    end

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "RULE " + name + " @" + loc._dbg(state.source))
    end

    match _body
    | let body': RuleNode[S, D, V] =>
      let self = this
      let parser = state.parser
      parser._parse_named_rule(
        consume state,
        depth,
        self,
        body',
        loc,
        {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
          let result'' =
            match result'
            | let success: Success[S, D, V] =>
              Success[S, D, V](
                self,
                success.start,
                success.next,
                state'.data,
                [success])
            else
              result'
            end
          ifdef debug then
            _Dbg.out(depth, "= " + result''.string())
          end
          outer(consume state', result'')
        })
    else
      let result =
        Failure[S, D, V](this, loc, state.data, ErrorMsg.rule_empty(name))
      ifdef debug then
        _Dbg.out(depth, "= " + result.string())
      end
      outer(consume state, result)
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
