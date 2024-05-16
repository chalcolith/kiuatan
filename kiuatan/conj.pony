use per = "collections/persistent"

class Conj[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithChildren[S, D, V]
  """
  Matches a sequence of child rules.
  """

  let _children: ReadSeq[RuleNode[S, D, V] box]
  let _action: (Action[S, D, V] | None)

  new create(
    children': ReadSeq[RuleNode[S, D, V] box],
    action': (Action[S, D, V] | None) = None)
  =>
    _children = children'
    _action = action'

  fun children(): ReadSeq[this->(RuleNode[S, D, V] box)] =>
    _children

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    ifdef debug then
      _Dbg.out(depth, "CONJ @" + loc.string())
    end

    if _children.size() == 0 then
      return Failure[S, D, V](this, loc, ErrorMsg.conjunction_empty())
    end

    let results: Array[Success[S, D, V]] trn = []
    var next = loc
    for child in _children.values() do
      match child.parse(parser, depth + 1, next)
      | let success: Success[S, D, V] =>
        results.push(success)
        next = success.next
      | let failure: Failure[S, D, V] =>
        let failure' = Failure[S, D, V](this, failure.start, None, failure)
        ifdef debug then
          _Dbg.out(depth, "= " + failure'.string())
        end
        return failure'
      end
    end

    let success = Success[S, D, V](this, loc, next, consume results)
    ifdef debug then
      _Dbg.out(depth, "= " + success.string())
    end
    success

  fun action(): (Action[S, D, V] | None) =>
    _action
