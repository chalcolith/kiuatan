use "collections"

class NamedRule[S, D: Any #share = None, V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """

  let name: String
  let memoize: Bool
  var _body: (RuleNode[S, D, V] box | None)
  var _action: (Action[S, D, V] | None)

  var weight: USize = 0
  var left_recursive: Bool = false

  new create(
    name': String,
    body': (RuleNode[S, D, V] box | None) = None,
    action': (Action[S, D, V] | None) = None,
    memoize': Bool = false)
  =>
    name = name'
    memoize = memoize'
    _body = body'
    _action = action'

    match _body
    | let node: RuleNode[S, D, V] box =>
      weight = _calc_weight(node, SetIs[RuleNode[S, D, V] box])
      left_recursive = _is_lr(node, SetIs[RuleNode[S, D, V] box])
    end

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
    match _body
    | let node: RuleNode[S, D, V] box =>
      weight = _calc_weight(node, SetIs[RuleNode[S, D, V] box])
      left_recursive = _is_lr(node, SetIs[RuleNode[S, D, V] box])
    end

  fun tag _calc_weight(
    node: RuleNode[S, D, V] box,
    seen: SetIs[RuleNode[S, D, V] box])
    : USize
  =>
    if seen.contains(node) then
      return 0
    end

    seen.set(node)
    match node
    | let named_rule: NamedRule[S, D, V] box =>
      if named_rule.weight == 0 then
        match named_rule._body
        | let body': RuleNode[S, D, V] box =>
          1 + _calc_weight(body', seen)
        else
          1
        end
      else
        1 + named_rule.weight
      end
    | let with_children: RuleNodeWithChildren[S, D, V] box =>
      var sum: USize = 1
      for child in with_children.children().values() do
        sum = sum + _calc_weight(child, seen)
      end
      sum
    | let with_body: RuleNodeWithBody[S, D, V] box =>
      match with_body.body()
      | let body': NamedRule[S, D, V] box =>
        1 + _calc_weight(body', seen)
      else
        1
      end
    else
      1
    end

  fun tag _is_lr(
    node: RuleNode[S, D, V] box,
    seen: SetIs[RuleNode[S, D, V] box])
    : Bool
  =>
    if seen.contains(node) then
      return true
    end

    seen.set(node)
    match node
    | let named_rule: NamedRule[S, D, V] box =>
      match named_rule._body
      | let body': RuleNode[S, D, V] box =>
        return _is_lr(body', seen)
      end
    | let conj: Conj[S, D, V] box =>
      try
        return _is_lr(conj.children()(0)?, seen)
      end
    | let disj: Disj[S, D, V] box =>
      for child in disj.children().values() do
        if _is_lr(child, seen) then
          return true
        end
      end
    | let with_body: RuleNodeWithBody[S, D, V] box =>
      match with_body.body()
      | let body': RuleNode[S, D, V] box =>
        return _is_lr(body', seen)
      end
    end
    false

  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    _Dbg() and _Dbg.out(
      depth, "RULE " + name + " @" + loc.string() +
      if left_recursive then " LR" else "" end +
      if memoize then " m" else "" end)

    match _body
    | let body': RuleNode[S, D, V] val =>
      let self = this

      // full on fancy stuff
      parser._parse_named_rule(depth, self, body', loc, outer)
    else
      let result =
        Failure[S, D, V](this, loc, ErrorMsg.rule_empty(name))
      _Dbg() and _Dbg.out(depth, name + " = " + result.string())
      outer(result)
    end

  fun action(): (Action[S, D, V] | None) =>
    _action
