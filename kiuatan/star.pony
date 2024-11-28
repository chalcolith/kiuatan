use per = "collections/persistent"

class Star[S, D: Any #share = None, V: Any #share = None]
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

  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  =>
    _Dbg() and _Dbg.out(
      depth, "STAR {" + _min.string() + "," +
      if _max < USize.max_value() then _max.string() else "" end +
      "} @" + loc.string())

    let results: Array[Success[S, D, V]] trn = []
    var next = loc
    var index: USize = 0
    while true do
      match _body.parse(parser, depth + 1, next)
      | let success: Success[S, D, V] =>
        if index == _max then
          let result = Failure[S, D, V](this, loc, ErrorMsg.star_too_long())
          _Dbg() and _Dbg.out(depth, "= " + result.string())
          return result
        end
        results.push(success)
        next = success.next
      | let failure: Failure[S, D, V] =>
        if index < _min then
          let result = Failure[S, D, V](this, loc, ErrorMsg.star_too_short())
          _Dbg() and _Dbg.out(depth, "    = " + result.string())
          return result
        end
        break
      end
      index = index + 1
    end

    let result = Success[S, D, V](this, loc, next, consume results)
    _Dbg() and _Dbg.out(depth, "    = " + result.string())
    result

  fun action(): (Action[S, D, V] | None) =>
    _action
