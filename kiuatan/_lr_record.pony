use per = "collections/persistent"

class val _LRRecord[S, V: Any #share]
  let rule: Rule[S, V]
  let exp: USize
  let start: Loc[S]
  let next: Loc[S]
  let lr: Bool
  let res: (Result[S, V] | None)
  let involved: per.SetIs[Rule[S, V]]

  new val create(
    rule': Rule[S, V],
    exp': USize,
    start': Loc[S],
    next': Loc[S],
    lr': Bool,
    res': (Result[S, V] | None),
    involved': per.SetIs[Rule[S, V]] = per.SetIs[Rule[S, V]])
  =>
    rule = rule'
    exp = exp'
    start = start'
    next = next'
    lr = lr'
    res = res'
    involved = involved'


type _LRByRule[S, V: Any #share] is
  per.MapIs[Rule[S, V] tag, _LRByLoc[S, V]]

type _LRByLoc[S, V: Any #share] is
  per.Map[Loc[S], _LRRecord[S, V]]

primitive _LRRecords[S, V: Any #share]
  fun _get_lr_record(recur: _LRByRule[S, V], rule: Rule[S, V], loc: Loc[S])
    : (_LRRecord[S, V] | None)
  =>
    try
      let loc_lr = recur(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun _set_lr_record(recur: _LRByRule[S, V], rule: Rule[S, V],
    lr: _LRRecord[S, V]) : _LRByRule[S, V]
  =>
    let loc_lr =
      try
        recur(rule)?
      else
        _LRByLoc[S, V]
      end
    recur.update(rule, loc_lr.update(lr.start, lr))

  fun _del_lr_record(recur: _LRByRule[S, V], rule: Rule[S, V], loc: Loc[S])
    : _LRByRule[S, V]
  =>
    let loc_lr =
      try
        recur(rule)?
      else
        _LRByLoc[S, V]
      end
    try
      recur.update(rule, loc_lr.remove(loc)?)
    else
      recur
    end
