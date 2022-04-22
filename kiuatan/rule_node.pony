use per = "collections/persistent"

interface val RuleNode[S, D: Any #share, V: Any #share]
  fun val not_recursive(stack: _RuleNodeStack[S, D, V]): Bool
  fun val parse(
    parser: Parser[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  fun val get_action(): (Action[S, D, V] | None)

type _RuleNodeStack[S, D: Any #share, V: Any #share]
  is per.List[RuleNode[S, D, V] tag]
