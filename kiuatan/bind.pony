use per = "collections/persistent"

class Bind[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]

  let variable: Variable
  let _body: RuleNode[S, D, V] box

  new create(
    variable': Variable,
    body': RuleNode[S, D, V] box)
  =>
    variable = variable'
    _body = body'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    _Dbg() and _Dbg.out(depth, "BIND " + variable.name + " @" + loc.string())

    let self = this
    _body.parse(
      parser,
      depth + 1,
      loc,
      {(result: Result[S, D, V]) =>
        // we need to insert a result node referencing us here so we can get the
        // binding when we're assembling values
        let result' =
          match result
          | let success: Success[S, D, V] =>
            Success[S, D, V](
              self,
              success.start,
              success.next,
              [success])
          else
            result
          end
        _Dbg() and _Dbg.out(
          depth, "= " + variable.name + " := " + result'.string())
        outer(result')
      })

  fun action(): (Action[S, D, V] | None) =>
    None
