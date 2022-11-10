use per = "collections/persistent"

trait val RuleNode[S, D: Any #share = None, V: Any #share = None]
  fun val cant_recurse(stack: _RuleNodeStack[S, D, V]): Bool
  fun val parse(
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  fun val get_action(): (Action[S, D, V] | None)

type _RuleNodeStack[S, D: Any #share, V: Any #share]
  is per.List[RuleNode[S, D, V] tag]
