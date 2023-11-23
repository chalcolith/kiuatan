use "collections"

class _LRRuleState[S, D: Any #share, V: Any #share]
  let depth: USize
  let rule: NamedRule[S, D, V] val
  let loc: Loc[S]
  let expansions: Array[Result[S, D, V]] = expansions.create()
  var lr_detected: Bool = false

  new create(
    depth': USize,
    rule': NamedRule[S, D, V] val,
    loc': Loc[S])
  =>
    depth = depth'
    rule = rule'
    loc = loc'

class val _LRRuleLocHash[S, D: Any #share, V: Any #share]
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
    hash(x) == hash(y)
