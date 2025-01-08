use "collections"

class NamedRule[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is RuleNodeWithBody[S, D, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """

  let name: String
  let memoize: Bool
  var _body: (RuleNode[S, D, V] | None)
  var _action: (Action[S, D, V] | None)

  var left_recursive: Bool = false

  new create(
    name': String,
    body': (RuleNode[S, D, V] | None) = None,
    action': (Action[S, D, V] | None) = None,
    memoize': Bool = false)
  =>
    name = name'
    memoize = memoize'
    _body = body'
    _action = action'
    set_left_recursive()

  fun action(): (Action[S, D, V] | None) =>
    _action

  fun body(): (this->(RuleNode[S, D, V]) | None) =>
    _body

  fun has_body(): Bool =>
    _body isnt None

  fun ref set_body(
    body': RuleNode[S, D, V],
    action': (Action[S, D, V] | None) = None)
  =>
    _body = body'
    if action' isnt None then
      _action = action'
    end
    set_left_recursive()

  fun ref set_left_recursive() =>
    let named_rules = SetIs[NamedRule[S, D, V]]
    _collect(this, named_rules)
    for nr in named_rules.values() do
      _set_lr(nr, SetIs[NamedRule[S, D, V]])
    end

  fun tag _collect(node: RuleNode[S, D, V], seen: SetIs[NamedRule[S, D, V]]) =>
    match node
    | let named_rule: NamedRule[S, D, V] =>
      if not seen.contains(named_rule) then
        seen.set(named_rule)
        match named_rule.body()
        | let body': RuleNode[S, D, V] =>
          _collect(body', seen)
        end
      end
    | let with_children: RuleNodeWithChildren[S, D, V] =>
      for child in with_children.children().values() do
        _collect(child, seen)
      end
    | let with_body: RuleNodeWithBody[S, D, V] =>
      match with_body.body()
      | let body': RuleNode[S, D, V] =>
        _collect(body', seen)
      end
    end

  fun tag _set_lr(node: RuleNode[S, D, V], seen: SetIs[NamedRule[S, D, V]]) =>
    match node
    | let named_rule: NamedRule[S, D, V] =>
      if seen.contains(named_rule) then
        named_rule.left_recursive = true
      else
        seen.set(named_rule)
        match named_rule.body()
        | let body': RuleNode[S, D, V] =>
          _set_lr(body', seen)
        end
      end
    | let conj: Conj[S, D, V] =>
      try
        _set_lr(conj.children()(0)?, seen)
      end
    | let disj: Disj[S, D, V] =>
      for child in disj.children().values() do
        _set_lr(child, seen)
      end
    | let with_body: RuleNodeWithBody[S, D, V] =>
      match with_body.body()
      | let body': RuleNode[S, D, V] =>
        _set_lr(body', seen)
      end
    end

  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V] =>
    _NamedRuleFrame[S, D, V](this, depth, loc, _body)

class _NamedRuleFrame[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  is _Frame[S, D, V]

  let rule: NamedRule[S, D, V] box
  let depth: USize
  let loc: Loc[S]
  let body: (RuleNode[S, D, V] box | None)

  new create(
    rule': NamedRule[S, D, V] box,
    depth': USize,
    loc': Loc[S],
    body': (RuleNode[S, D, V] box | None))
  =>
    rule = rule'
    depth = depth'
    loc = loc'
    body = body'

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    // can't happen; parser should not call this
    Failure[S, D, V](rule, loc, "NamedRuleFrame.run() should not be called")
