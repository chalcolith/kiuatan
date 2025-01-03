use "collections"

class _LRRuleState[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  let depth: USize
  let rule: NamedRule[S, D, V] box
  let loc: Loc[S]
  let topmost: Bool
  let expansions: Array[Result[S, D, V]] = expansions.create()
  var lr_detected: Bool = false

  new create(
    depth': USize,
    rule': NamedRule[S, D, V] box,
    loc': Loc[S],
    topmost': Bool)
  =>
    depth = depth'
    rule = rule'
    loc = loc'
    topmost = topmost'

class val _LRRuleLocHash[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  is HashFunction[(NamedRule[S, D, V] box, Loc[S])]

  new val create() =>
    None

  fun hash(x: (NamedRule[S, D, V] box, Loc[S])): USize =>
    x._1.name.hash() xor x._2.hash()

  fun eq(
    x: (NamedRule[S, D, V] box, Loc[S]),
    y: (NamedRule[S, D, V] box, Loc[S]))
    : Bool
  =>
    (x._1.name == y._1.name) and (x._2 == y._2)
