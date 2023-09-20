use per = "collections/persistent"

trait val RuleNode[S, D: Any #share, V: Any #share]
  fun val parse(
    parser: Parser[S, D, V],
    depth: USize,
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  fun val get_action(): (Action[S, D, V] | None)

trait val RuleNodeWithChildren[S, D: Any #share, V: Any #share]
  is RuleNode[S, D, V]
  fun children(): ReadSeq[this->(RuleNode[S, D, V] box)]

trait val RuleNodeWithBody[S, D: Any #share, V: Any #share]
  is RuleNode[S, D, V]
  fun body(): (this->(RuleNode[S, D, V] box) | None)
