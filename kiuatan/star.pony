use per = "collections/persistent"

class val Star[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]

  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, D, V] box
  let _min: USize
  let _max: USize
  let _action: (Action[S, D, V] | None)

  new create(
    body: RuleNode[S, D, V] box,
    min: USize = 0,
    action: (Action[S, D, V] | None) = None,
    max: USize = USize.max_value())
  =>
    _body = body
    _min = min
    _max = max
    _action = action

  fun val cant_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule: RuleNode[S, D, V] tag = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body.cant_recurse(stack.prepend(rule))
    end

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "STAR {" + _min.string() + "," +
        if _max < USize.max_value() then _max.string() else "" end +
        "} @" + loc._dbg(state.source))
    end

    _parse_child(
      consume state,
      depth,
      loc,
      0,
      loc,
      per.Lists[Success[S, D, V]].empty(),
      outer)

  fun val _parse_child(
    state: _ParseState[S, D, V],
    depth: USize,
    start: Loc[S],
    index: USize,
    loc: Loc[S],
    results: per.List[Success[S, D, V]],
    outer: _Continuation[S, D, V])
  =>
    let self = this
    _body.parse(consume state, depth + 1, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        let result'' =
          match result'
          | let success: Success[S, D, V] =>
            if index == _max then
              Failure[S, D, V](self, start, state'.data,
                ErrorMsg.star_too_long())
            else
              self._parse_child(
                consume state',
                depth,
                start,
                index + 1,
                success.next,
                results.prepend(success),
                outer)
              return
            end
          | let failure: Failure[S, D, V] =>
            if index < _min then
              Failure[S, D, V](self, start, state'.data,
                ErrorMsg.star_too_short())
            else
              Success[S, D, V](
                self,
                start,
                loc,
                state'.data,
                results.reverse())
            end
          end
        ifdef debug then
          _Dbg.out(depth, "< " + result''.string())
        end
        outer(consume state', result'')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
