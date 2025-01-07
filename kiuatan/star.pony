class Star[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, D, V]
  let _min: USize
  let _max: USize
  let _action: (Action[S, D, V] | None)

  new create(
    body': RuleNode[S, D, V],
    min': USize = 0,
    action': (Action[S, D, V] | None) = None,
    max': USize = USize.max_value())
  =>
    _body = body'
    _min = min'
    _max = max'
    _action = action'

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun body(): (this->(RuleNode[S, D, V]) | None) =>
    _body

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _StarFrame[S, D, V](this, depth, loc, _min, _max, _body)

class _StarFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is _Frame[S, D, V]

  let _rule: RuleNode[S, D, V] box
  let _depth: USize
  let _loc: Loc[S]
  let _min: USize
  let _max: USize
  let _body: RuleNode[S, D, V] box
  let _results: Array[Success[S, D, V]]
  var _num_matched: USize
  var _cur_loc: Loc[S]

  new create(
    rule: RuleNode[S, D, V] box,
    depth: USize,
    loc: Loc[S],
    min: USize,
    max: USize,
    body: RuleNode[S, D, V] box)
  =>
    _rule = rule
    _depth = depth
    _loc = loc
    _min = min
    _max = max
    _body = body
    _results = _results.create()
    _num_matched = 0
    _cur_loc = _loc

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    match child_result
    | let success: Success[S, D, V] =>
      _num_matched = _num_matched + 1
      _cur_loc = success.next
      if _num_matched > _max then
        let result = Failure[S, D, V](_rule, _loc, ErrorMsg.star_too_long())
        _Dbg() and _Dbg.out(_depth, "= " + result.string())
        result
      else
        _results.push(success)
        _body.call(_depth + 1, _cur_loc)
      end
    | let failure: Failure[S, D, V] =>
      _cur_loc = failure.start
      let result =
        if _num_matched < _min then
          Failure[S, D, V](_rule, _loc, ErrorMsg.star_too_short())
        else
          Success[S, D, V](_rule, _loc, _cur_loc, _results)
        end
      _Dbg() and _Dbg.out(_depth, "= " + result.string())
      result
    else
      _Dbg() and _Dbg.out(
        _depth, "STAR {" + _min.string() + "," +
        if _max < USize.max_value() then _max.string() else "" end +
        "} @" + _loc.string())
      _body.call(_depth + 1, _cur_loc)
    end
