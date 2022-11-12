class val Disj[S, D: Any #share = None, V: Any #share = None]
  is RuleNode[S, D, V]
  """
  Matches one out of a list of possible alternatives.  Tries each alternative in
  order.  If one alternative fails, but an outer rule later fails, will *not*
  backtrack to another alternative.
  """

  let _children: ReadSeq[RuleNode[S, D, V] box]
  let _action: (Action[S, D, V] | None)

  new create(
    children: ReadSeq[RuleNode[S, D, V] box],
    action: (Action[S, D, V] | None) = None)
  =>
    _children = children
    _action = action

  fun might_recurse(stack: _RuleNodeStack[S, D, V]): Bool =>
    _ChildrenMightRecurse[S, D, V](this, _children, stack)

  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "DISJ @" + loc._dbg(state.source))
    end
    _parse_child(consume state, depth, 0, loc, None, outer)

  fun val _parse_child(
    state: _ParseState[S, D, V],
    depth: USize,
    child_index: USize,
    loc: Loc[S],
    last_failure: (Failure[S, D, V] | None),
    outer: _Continuation[S, D, V])
  =>
    if child_index == _children.size() then
      let result = Failure[S, D, V](this, loc, state.data, None, last_failure)
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
              let result'' = Success[S, D, V](
                self,
                loc,
                success.next,
                state'.data,
                [success])
              ifdef debug then
                _Dbg.out(depth, "= " + result''.string())
              end
              outer(consume state', result'')
            | let failure: Failure[S, D, V] =>
              self._parse_child(
                consume state', depth, child_index + 1, loc, failure, outer)
            end
          })
      else
        let result = Failure[S, D, V](this, loc, state.data,
          ErrorMsg.disjunction_failed(), None)
        ifdef debug then
          _Dbg.out(depth, "= " + result.string())
        end
        outer(consume state, result)
      end
    end

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
