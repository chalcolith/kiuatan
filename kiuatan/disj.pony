
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

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    _Dbg() and _Dbg.out(depth, "DISJ @" + loc.string())

    if _children.size() == 0 then
      outer(Failure[S, D, V](this, loc, ErrorMsg.disjunction_empty()))
      return
    end

    _parse_child(parser, depth, 0, loc, None, outer)

    // let disj = _DisjInstance
    // let self = this
    // parser._parse_disjunction_start(
    //   this,
    //   disj,
    //   _children.size(),
    //   depth,
    //   loc,
    //   {()(children: ReadSeq[RuleNode[S, D, V] box] val = _children) =>
    //     var index: USize = 0
    //     for child in children.values() do
    //       parser._parse_disjunction_child(
    //         disj, index, self, child, depth, loc, outer)
    //       index = index + 1
    //     end
    //   },
    //   outer)

  fun val _parse_child(
    parser: Parser[S, D, V],
    depth: USize,
    child_index: USize,
    loc: Loc[S],
    last_failure: (Failure[S, D, V] | None),
    outer: _Continuation[S, D, V])
  =>
    if child_index == _children.size() then
      let result = Failure[S, D, V](
        this, loc, ErrorMsg.disjunction_none(), last_failure)
      _Dbg() and _Dbg.out(depth, "< " + result.string())
      outer(result)
    else
      match try _children(child_index)? end
      | let child: RuleNode[S, D, V] val =>
        let self = this
        child.parse(parser, depth + 1, loc,
          {(result: Result[S, D, V]) =>
            match result
            | let success: Success[S, D, V] =>
              let success' = Success[S, D, V](
                self,
                loc,
                success.next,
                [success])
              _Dbg() and _Dbg.out(depth, "= " + success'.string())
              outer(success')
            | let failure: Failure[S, D, V] =>
              self._parse_child(
                parser, depth, child_index + 1, loc, failure, outer)
            end
          })
      else
        let result = Failure[S, D, V](
          this, loc, ErrorMsg.disjunction_failed(), None)
        _Dbg() and _Dbg.out(depth, "= " + result.string())
        outer(result)
      end
    end

  fun action(): (Action[S, D, V] | None) =>
    _action

class val _DisjInstance
  new val create() => None
