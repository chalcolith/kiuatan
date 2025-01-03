trait box RuleNode[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]

  fun action(): (Action[S, D, V] | None)
  fun call(depth: USize, loc: Loc[S]): _RuleFrame[S, D, V]

trait box RuleNodeWithChildren[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  is RuleNode[S, D, V]

  fun children(): ReadSeq[this->(RuleNode[S, D, V])]

trait box RuleNodeWithBody[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  is RuleNode[S, D, V]

  fun body(): (this->(RuleNode[S, D, V]) | None)
