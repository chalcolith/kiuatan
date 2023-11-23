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

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "CONJ @" + loc.string())
    end

    _parse_child(
      parser,
      depth,
      loc,
      0,
      loc,
      per.Lists[Success[S, D, V]].empty(),
      outer)

  fun val _parse_child(
    parser: Parser[S, D, V],
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
        results.reverse())

      ifdef debug then
        _Dbg.out(depth, "= " + result.string())
      end

      outer(result)
    else
      match try _children(child_index)? end
      | let child: RuleNode[S, D, V] val =>
        let self = this
        child.parse(parser, depth + 1, loc,
          {(result: Result[S, D, V]) =>
            match result
            | let success: Success[S, D, V] =>
              self._parse_child(
                parser,
                depth,
                start,
                child_index + 1,
                success.next,
                results.prepend(success),
                outer)
            | let failure: Failure[S, D, V] =>
              let failure' = Failure[S, D, V](self, start, None, failure)
              ifdef debug then
                _Dbg.out(depth, "= " + failure'.string())
              end
              outer(failure')
            end
          })
      else
        let result = Failure[S, D, V](
          this, start, ErrorMsg.conjunction_failed())
        ifdef debug then
          _Dbg.out(depth, "= " + result.string())
        end
        outer(result)
      end
    end

  fun action(): (Action[S, D, V] | None) =>
    _action
