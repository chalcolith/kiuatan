
class Disj[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithChildren[S, D, V]
  """
  Matches one out of a list of possible alternatives.  Tries each alternative in
  order.  If one alternative fails, but an outer rule later fails, will *not*
  backtrack to another alternative.
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
      _Dbg.out(depth, "DISJ @" + loc.string())
    end

    if _children.size() == 0 then
      return Failure[S, D, V](this, loc, ErrorMsg.disjunction_empty())
    end

    let message: String trn = String
    for child in _children.values() do
      match child.parse(parser, depth + 1, loc)
      | let success: Success[S, D, V] =>
        let result = Success[S, D, V](this, loc, success.next, [success])
        ifdef debug then
          _Dbg.out(depth, "     = " + result.string())
        end
        return result
      | let failure: Failure[S, D, V] =>
        if message.size() > 0 then
          message.append("; ")
        end
        message.append(failure.get_message())
      end
    end

    let result = Failure[S, D, V](this, loc, consume message)
    ifdef debug then
      _Dbg.out(depth, "     = " + result.string())
    end
    result

  fun action(): (Action[S, D, V] | None) =>
    _action

class val _DisjInstance
  new val create() => None
