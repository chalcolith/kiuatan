use per = "collections/persistent"

class val Cond[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let _body: RuleNode[S, D, V] box
  let _cond: {(Success[S, D, V]): (Bool, (String | None))} val

  new create(
    body': RuleNode[S, D, V] box,
    cond': {(Success[S, D, V]): (Bool, (String | None))} val)
  =>
    _body = body'
    _cond = cond'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "COND @" + loc.string())
    end
    let self = this
    _body.parse(parser, depth + 1, loc,
      {(result: Result[S, D, V]) =>
        let result' =
          match result
          | let success: Success[S, D, V] =>
            (let succeeded: Bool, let message: (String | None)) = _cond(success)
            if succeeded then
              success
            else
              Failure[S, D, V](self, success.start, message)
            end
          | let failure: Failure[S, D, V] =>
            failure
          end
        ifdef debug then
          _Dbg.out(depth, "= " + result'.string())
        end
        outer(result')
      })

  fun val get_action(): (Action[S, D, V] | None) =>
    None
