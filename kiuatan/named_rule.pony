use per = "collections/persistent"

class NamedRule[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """

  let name: String
  let memoize: Bool
  var _body: (RuleNode[S, D, V] box | None)
  var _action: (Action[S, D, V] | None)

  new create(
    name': String,
    body': (RuleNode[S, D, V] box | None) = None,
    action': (Action[S, D, V] | None) = None,
    memoize': Bool = false)
  =>
    name = name'
    _body = body'
    _action = action'
    memoize = memoize'

  fun body(): (this->(RuleNode[S, D, V] box) | None) =>
    _body

  fun has_body(): Bool =>
    _body isnt None

  fun ref set_body(
    body': RuleNode[S, D, V] box,
    action': (Action[S, D, V] | None) = None)
  =>
    _body = body'
    if action' isnt None then
      _action = action'
    end

  fun val parse(
    parser: _ParseNamedRule[S, D, V],
    depth: USize,
    loc: Loc[S])
    : Result[S, D, V]
  =>
    _Dbg() and _Dbg.out(depth, "RULE " + name + " @" + loc.string())

    let result =
      match _body
      | let body': RuleNode[S, D, V] val =>
        match parser(depth, this, body', loc)
        | let success: Success[S, D, V] =>
          Success[S, D, V](this, success.start, success.next, [success])
        | let failure: Failure[S, D, V] =>
          Failure[S, D, V](
            this, loc, ErrorMsg.rule_expected(name, loc.string()), failure)
        end
      else
        Failure[S, D, V](this, loc, ErrorMsg.rule_empty(name))
      end
    _Dbg() and _Dbg.out(depth, "     " + name + " = " + result.string())
    result

  fun action(): (Action[S, D, V] | None) =>
    _action
