use per = "collections/persistent"

trait val RuleNode[S, D: Any #share, V: Any #share]
  fun might_recurse(stack: _RuleNodeStack[S, D, V]): Bool
  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  fun val get_action(): (Action[S, D, V] | None)

primitive _BodyMightRecurse[S, D: Any #share, V: Any #share]
  fun apply(
    self: RuleNode[S, D, V] tag,
    body: (RuleNode[S, D, V] box | None),
    stack: _RuleNodeStack[S, D, V])
    : Bool
  =>
    for node in stack.values() do
      if node is self then return true end
    end
    match body
    | let body': RuleNode[S, D, V] box =>
      body'.might_recurse(stack.prepend(self))
    else
      false
    end

primitive _ChildrenMightRecurse[S, D: Any #share, V: Any #share]
  fun apply(
    self: RuleNode[S, D, V] tag,
    children: ReadSeq[RuleNode[S, D, V] box],
    stack: _RuleNodeStack[S, D, V])
    : Bool
  =>
    for node in stack.values() do
      if node is self then return true end
    end
    let stack' = stack.prepend(self)
    for child in children.values() do
      if child.might_recurse(stack') then return true end
    end
    false

type _RuleNodeStack[S, D: Any #share, V: Any #share]
  is per.List[RuleNode[S, D, V] tag]
