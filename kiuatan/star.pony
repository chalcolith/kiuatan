use per = "collections/persistent"

class val Star[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, D, V] box
  let _min: USize
  let _max: USize
  let _action: (Action[S, D, V] | None)

  new create(
    body': RuleNode[S, D, V] box,
    min': USize = 0,
    action': (Action[S, D, V] | None) = None,
    max': USize = USize.max_value())
  =>
    _body = body'
    _min = min'
    _max = max'
    _action = action'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "STAR {" + _min.string() + "," +
        if _max < USize.max_value() then _max.string() else "" end +
        "} @" + loc.string())
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
    index: USize,
    loc: Loc[S],
    results: per.List[Success[S, D, V]],
    outer: _Continuation[S, D, V])
  =>
    let self = this
    _body.parse(parser, depth + 1, loc,
      {(result: Result[S, D, V]) =>
        let result' =
          match result
          | let success: Success[S, D, V] =>
            if index == _max then
              Failure[S, D, V](self, start, ErrorMsg.star_too_long())
            else
              self._parse_child(
                parser,
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
              Failure[S, D, V](self, start, ErrorMsg.star_too_short())
            else
              Success[S, D, V](
                self,
                start,
                loc,
                results.reverse())
            end
          end
        ifdef debug then
          _Dbg.out(depth, "= " + result'.string())
        end
        outer(result')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    _action
