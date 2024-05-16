use per = "collections/persistent"

trait RuleNode[S, D: Any #share, V: Any #share]
  fun val parse(parser: _ParseNamedRule[S, D, V], depth: USize, loc: Loc[S])
    : Result[S, D, V]
  fun action(): (Action[S, D, V] | None)

trait RuleNodeWithChildren[S, D: Any #share, V: Any #share]
  is RuleNode[S, D, V]
  fun children(): ReadSeq[this->(RuleNode[S, D, V] box)]

trait RuleNodeWithBody[S, D: Any #share, V: Any #share]
  is RuleNode[S, D, V]
  fun body(): (this->(RuleNode[S, D, V] box) | None)
