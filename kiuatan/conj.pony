use per = "collections/persistent"

class val Conj[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches a sequence of child rules.
  """

  let _children: ReadSeq[RuleNode[S, D, V] box]
  let _action: (Action[S, D, V] | None)

  new create(
    children: ReadSeq[RuleNode[S, D, V] box],
    action: (Action[S, D, V] | None) = None)
  =>
    _children = children
    _action = action

  fun val cant_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      let stack' = stack.prepend(rule)
      for child in _children.values() do
        if not child.cant_recurse(stack') then
          return false
        end
      end
      true
    end

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "CONJ @" + loc._dbg(state.source))
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
    child_index: USize,
    loc: Loc[S],
    results: per.List[Success[S, D, V]],
    outer: _Continuation[S, D, V])
  =>
    if child_index == _children.size() then
      let result = Success[S, D, V](
        this,
        start,
        loc,
        state.data,
        results.reverse())

      ifdef debug then
        _Dbg.out(depth, "< " + result.string())
      end

      outer(consume state, result)
    else
      match try _children(child_index)? end
      | let child: RuleNode[S, D, V] =>
        let self = this
        child.parse(consume state, depth + 1, loc,
          {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
            match result'
            | let success: Success[S, D, V] =>
              self._parse_child(
                consume state',
                depth,
                start,
                child_index + 1,
                success.next,
                results.prepend(success),
                outer)
            | let failure: Failure[S, D, V] =>
              let result'' = Failure[S, D, V](
                self, start, state'.data, None, failure)
              ifdef debug then
                _Dbg.out(depth, "< " + result''.string())
              end
              outer(consume state', result'')
            end
          })
      else
        let result = Failure[S, D, V](
          this, start, state.data, ErrorMsg.conjunction_failed())
        ifdef debug then
          _Dbg.out(depth, "< " + result.string())
        end
        outer(consume state, result)
      end
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
