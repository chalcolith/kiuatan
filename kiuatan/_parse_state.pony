use "collections"

class iso _ParseState[S, D: Any #share, V: Any #share]
  let parser: Parser[S, D, V]
  let data: D
  let source: Source[S]
  let lr_stack: Map[Loc[S], Array[_LRState[S, D, V]]]

  new iso create(parser': Parser[S, D, V], data': D, source': Source[S]) =>
    parser = parser'
    data = data'
    source = source'
    lr_stack = Map[Loc[S], Array[_LRState[S, D, V]]]

class iso _LRState[S, D: Any #share, V: Any #share]
  let node: RuleNode[S, D, V]
  let loc: Loc[S]
  let lr_depth: USize
  let expansions: Array[Result[S, D, V]] box
  var lr_detected: Bool

  new create(
    node': RuleNode[S, D, V],
    loc': Loc[S],
    lr_depth': USize,
    expansions': Array[Result[S, D, V]] box)
  =>
    node = node'
    loc = loc'
    lr_depth = lr_depth'
    expansions = expansions'
    lr_detected = false
