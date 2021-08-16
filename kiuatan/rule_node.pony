use per = "collections/persistent"

interface val RuleNode[S, V: Any #share = None]
  fun val _is_terminal(stack: per.List[RuleNode[S, V] tag]): Bool
  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Continuation[S, V])
  fun val _get_action(): (Action[S, V] | None)
