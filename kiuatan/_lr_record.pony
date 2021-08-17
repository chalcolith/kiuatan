use per = "collections/persistent"

class val _LRRecord[S, D: Any #share, V: Any #share]
  let rule: NamedRule[S, D, V]
  let exp: USize
  let start: Loc[S]
  let next: Loc[S]
  let lr: Bool
  let res: (Result[S, D, V] | None)
  let involved: _InvolvedSet[S, D, V]

  new val create(
    rule': NamedRule[S, D, V],
    exp': USize,
    start': Loc[S],
    next': Loc[S],
    lr': Bool,
    res': (Result[S, D, V] | None),
    involved': _InvolvedSet[S, D, V] = _InvolvedSet[S, D, V])
  =>
    rule = rule'
    exp = exp'
    start = start'
    next = next'
    lr = lr'
    res = res'
    involved = involved'

type _InvolvedSet[S, D: Any #share, V: Any #share] is
  per.SetIs[NamedRule[S, D, V]]

type _LRByRule[S, D: Any #share, V: Any #share] is
  per.MapIs[NamedRule[S, D, V] tag, _LRByLoc[S, D, V]]

type _LRByLoc[S, D: Any #share, V: Any #share] is
  per.Map[Loc[S], _LRRecord[S, D, V]]

type _LRStack[S, D: Any #share, V: Any #share] is per.List[_LRRecord[S, D, V]]

primitive _LRRecords[S, D: Any #share, V: Any #share]
  fun _get_lr_record(recur: _LRByRule[S, D, V], rule: NamedRule[S, D, V],
    loc: Loc[S]) : (_LRRecord[S, D, V] | None)
  =>
    try
      let loc_lr = recur(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun _set_lr_record(recur: _LRByRule[S, D, V], rule: NamedRule[S, D, V],
    lr: _LRRecord[S, D, V]) : _LRByRule[S, D, V]
  =>
    let loc_lr =
      try
        recur(rule)?
      else
        _LRByLoc[S, D, V]
      end
    recur.update(rule, loc_lr.update(lr.start, lr))

  fun _del_lr_record(recur: _LRByRule[S, D, V], rule: NamedRule[S, D, V],
    loc: Loc[S]) : _LRByRule[S, D, V]
  =>
    let loc_lr =
      try
        recur(rule)?
      else
        _LRByLoc[S, D, V]
      end
    try
      recur.update(rule, loc_lr.remove(loc)?)
    else
      recur
    end
