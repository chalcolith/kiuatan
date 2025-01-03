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

    left_recursive =
      match _body
      | let node: RuleNode[S, D, V] =>
        _is_lr(node, SetIs[RuleNode[S, D, V]])
      else
        false
      end

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
    left_recursive =
      match _body
      | let node: RuleNode[S, D, V] =>
        _is_lr(node, SetIs[RuleNode[S, D, V]])
      else
        false
      end

  fun tag _is_lr(
    node: RuleNode[S, D, V],
    seen: SetIs[RuleNode[S, D, V]])
    : Bool
  =>
    if seen.contains(node) then
      return true
    end

    seen.set(node)
    match node
    | let named_rule: NamedRule[S, D, V] box =>
      match named_rule._body
      | let body': RuleNode[S, D, V] =>
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
      | let body': RuleNode[S, D, V] =>
        return _is_lr(body', seen)
      end
    end
    false

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
  let body: (RuleNode[S, D, V] | None)

  new create(
    rule': NamedRule[S, D, V] box,
    depth': USize,
    loc': Loc[S],
    body': (RuleNode[S, D, V] | None))
  =>
    rule = rule'
    depth = depth'
    loc = loc'
    body = body'

  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V] =>
    // can't happen; parser should not call this
    Failure[S, D, V](rule, loc, "NamedRuleFrame.run() should not be called")
