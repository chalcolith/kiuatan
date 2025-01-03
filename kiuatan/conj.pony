
class Conj[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithChildren[S, D, V]
  """
  Matches a sequence of child rules.
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
    _ConjFrame[S, D, V](this, depth, loc, _children)

class _ConjFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V]
  let _depth: USize
  let _loc: Loc[S]
  let _children: ReadSeq[RuleNode[S, D, V]]
  let _results: Array[Success[S, D, V]]
  var _cur_loc: Loc[S]
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
    _results = _results.create(_children.size())
    _cur_loc = _loc
    _child_index = 0

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      _results.push(success)
      _child_index = _child_index + 1
      _cur_loc = success.next
      if _child_index == _children.size() then
        let result = Success[S, D, V](_rule, _loc, _cur_loc, _results.clone())
        _Dbg() and _Dbg.out(_depth, "= " + result.string())
        return result
      end
      // fall through
    | let failure: Failure[S, D, V] =>
      _Dbg() and _Dbg.out(_depth, "= child failed")
      return Failure[S, D, V](_rule, _loc, None, failure)
    end

    try
      if _child_index == 0 then
        _Dbg() and _Dbg.out(_depth, "CONJ @" + _loc.string())
      end
      _children(_child_index)?.call(_depth + 1, _cur_loc)
    else
      _Dbg() and _Dbg.out(_depth, "= invalid child index")
      Failure[S, D, V](_rule, _loc, ErrorMsg.conjunction_failed())
    end
