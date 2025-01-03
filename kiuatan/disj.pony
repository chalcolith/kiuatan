
class Disj[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithChildren[S, D, V]
  """
  Matches one out of a list of possible alternatives.  Tries each alternative in
  order.  If one alternative fails, but an outer rule later fails, will *not*
  backtrack to another alternative.
  """

  let _children: ReadSeq[RuleNode[S, D, V]]
  let _action: (Action[S, D, V] | None)

  new create(
    children': ReadSeq[RuleNode[S, D, V]],
    action': (Action[S, D, V] | None) = None)
  =>
    _children = children'
    _action = action'

  fun children(): ReadSeq[this->(RuleNode[S, D, V])] =>
    _children

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _DisjFrame[S, D, V](this, depth, loc, _children)

class _DisjFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _children: ReadSeq[RuleNode[S, D, V]]
  var _child_index: USize

  new create(
    rule: RuleNode[S, D, V],
    depth: USize,
    loc: Loc[S],
    children: ReadSeq[RuleNode[S, D, V]])
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _children = children
    _child_index = 0

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      let result = Success[S, D, V](_rule, _loc, success.next, [ success ])
      _Dbg() and _Dbg.out(_depth, "= " + result.string())
      return result
    | let failure: Failure[S, D, V] =>
      _child_index = _child_index + 1
      if _child_index == _children.size() then
        var message = ErrorMsg.disjunction_none()

        // a common pattern is to have an Error node last in a disjunction
        // in this case bubble up the error message
        var rightmost = failure
        while true do
          if rightmost.from_error then
            message = rightmost.get_message()
            break
          end
          match rightmost.inner
          | let inner': Failure[S, D, V] =>
            rightmost = inner'
          else
            break
          end
        end

        let result = Failure[S, D, V](_rule, _loc, message)
        _Dbg() and _Dbg.out(_depth, "= " + result.string())
        return result
      end
      // fall through
    end

    try
      if _child_index == 0 then
        _Dbg() and _Dbg.out(_depth, "DISJ @" + _loc.string())
      end
      _children(_child_index)?.call(_depth + 1, _loc)
    else
      _Dbg() and _Dbg.out(_depth, "= invalid child index")
      Failure[S, D, V](_rule, _loc, ErrorMsg.disjunction_failed())
    end
