
use "debug"
use mut="collections"
use "collections/persistent"

actor Parser[S, V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior parses.
  Also used to initiate a parse attempt.
  """

  var _segments: List[Segment[S]]
  var _updates: List[_UpdateSeg[S]] = Nil[_UpdateSeg[S]]

  let _memo: _Memo[S, V] = _memo.create()

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = Lists[Segment[S]].from(source.values())

  fun num_segments(): USize =>
    """
    Returns the number of segments currently in the source.
    """
    _segments.size()

  be insert_segment(index: USize, segment: Segment[S]) =>
    """
    Insert a source segment at the given index.  The insertion will happen upon the next call to `parse()`.
    """
    let insert = _InsertSeg[S](index, segment)
    _updates = _updates.concat(Cons[_UpdateSeg[S]](insert, Nil[_UpdateSeg[S]]))

  be remove_segment(index: USize) =>
    """
    Removes the source segment at the given index.  The removal will happen upon the next call to `parse()`.
    """
    let remove = _RemoveSeg(index)
    _updates = _updates.concat(Cons[_UpdateSeg[S]](remove, Nil[_UpdateSeg[S]]))

  fun ref _update_segments() =>
    for op in _updates.values() do
      match op
      | let insert: _InsertSeg[S] =>
        let left = _segments.take(insert.index)
        let right = _segments.drop(insert.index)
        _segments = left
          .concat(Cons[Segment[S]](insert.segment, Nil[Segment[S]]))
          .concat(right)
      | let remove: _RemoveSeg =>
        let left = _segments.take(remove.index)
        let right = _segments.take(remove.index + 1)
        _segments = left.concat(right)
      end
    end
    _updates = Lists[_UpdateSeg[S]].empty()

  be parse(rule: RuleNode[S, V], callback: ParseCallback[S, V],
    start: (Loc[S] | None) = None, clear_memo: Bool = false)
  =>
    """
    Initiates a parse attempt with the given rule.
    """
    if clear_memo then
      _memo.clear()
    end

    let stack = Lists[_LRRecord[S, V]].empty()
    let recur = _LRByRule[S, V]

    match _segments
    | let source: Cons[Segment[S]] =>
      _update_segments()
      let start': Loc[S] =
        match start
        | let loc: Loc[S] =>
          loc
        else
          Loc[S](source, 0)
        end

      let cont =
        recover
          {(result: Result[S, V], stack: List[_LRRecord[S, V]],
            recur: _LRByRule[S, V])
          =>
            callback(result)
          }
        end
      _parse_with_memo(rule, source, start', stack, recur, consume cont)
    else
      let pos =
        match start
        | let loc: Loc[S] =>
          loc
        else
          Loc[S](Cons[Segment[S]]([], Nil[Segment[S]]), 0)
        end
      callback(Failure[S, V](rule, pos, "cannot parse empty source"))
    end

  be _parse_with_memo(
    node: RuleNode[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    match node
    | let rule: Rule[S, V] =>
      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_with_memo: " + rule.name + "@" +
          loc.string() + ": " +
          (if rule._is_terminal() then "terminal" else "nonterminal" end))
      end

      match _lookup(rule, loc, 0)
      | let result: Result[S, V] =>
        ifdef debug then
          Dbg[S, V]._dbg(stack, "_parse_with_memo: " + rule.name + "@" +
            loc.string() + ": from memo: " + result.string())
        end
        cont(result, stack, recur)
      else
        if rule._is_terminal() then
          _parse_non_lr(rule, src, loc, stack, recur, cont)
        else
          _parse_lr(rule, src, loc, stack, recur, cont)
        end
      end
    else
      node._parse(this, src, loc, stack, recur, cont)
    end

  fun _parse_non_lr(
    rule: Rule[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let stack' = stack.prepend(_LRRecord[S, V](rule, 0, loc, loc, false, None))
    let parser: Parser[S, V] = this
    rule._parse(this, src, loc, stack', recur,
      {(result: Result[S, V], stack'': List[_LRRecord[S, V]],
        recur': _LRByRule[S, V])(cont)
      =>
        ifdef debug then
          Dbg[S, V]._dbg(stack'', "_parse_non_lr: " + rule.name + ":0@" +
            loc.string() + ": " + result.string())
        end
        parser._memoize(rule, loc, 0, result, {() =>
          cont(result, stack''.drop(1), recur')
        })
      })

  fun _parse_lr(
    rule: Rule[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    match _LRR[S, V]._get_lr_record(recur, rule, loc)
    | let rec: _LRRecord[S, V] =>
      _parse_existing_lr(rule, rec, stack, recur, cont)
    else
      _parse_new_lr(rule, src, loc, stack, recur, cont)
    end

  fun _parse_existing_lr(rule: Rule[S, V], rec: _LRRecord[S, V],
    stack: List[_LRRecord[S, V]], recur: _LRByRule[S, V], cont: _Cont[S, V])
  =>
    var involved = rec.involved
    for lr in stack.reverse().values() do
      if lr.rule is rule then break end
      involved = involved.add(rule)
    end
    match _lookup(rule, rec.start, rec.exp)
    | let success: Success[S, V] =>
      let rec' = _LRRecord[S, V](rec.rule, rec.exp, rec.start, success.next,
        true, success, involved)
      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec'.exp.string() + "@[" + rec'.start.string() + "," +
          rec'.next.string() + "): result " + success.string())
      end
      cont(success, stack, _LRR[S, V]._set_lr_record(recur, rule, rec'))
    | let failure: Failure[S, V] =>
      let rec' = _LRRecord[S, V](rec.rule, rec.exp, rec.start, rec.start,
        true, failure, involved)
      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec'.exp.string() + "@" + rec'.start.string() + ": result " +
          failure.string())
      end
      cont(failure, stack, _LRR[S, V]._set_lr_record(recur, rule, rec'))
    else // can't happen
      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec.exp.string() + "@" + rec.start.string() +
          ": FAILED; CAN'T HAPPEN")
      end
      cont(Failure[S, V](rule, rec.start, "LR not memoized"), stack, recur)
    end

  fun _parse_new_lr(rule: Rule[S, V], src: Source[S], loc: Loc[S],
    stack: List[_LRRecord[S, V]], recur: _LRByRule[S, V], cont: _Cont[S, V])
  =>
    let rec' = _LRRecord[S, V](rule, 1, loc, loc, false, None,
      SetIs[Rule[S, V]])
    let stack' = stack.prepend(rec')
    let recur' = _LRR[S, V]._set_lr_record(recur, rule, rec')

    ifdef debug then
      Dbg[S, V]._dbg(stack', "_parse_new_lr: memoize " + rule.name + ":" +
        rec'.exp.string() + "@" + loc.string() + " failure")
    end

    let self: Parser[S, V] tag = this
    _memoize(rule, loc, rec'.exp, Failure[S, V](rule, loc, "LR started"),
      self~_parse_new_lr_aux1(0, rule, src, loc, stack', recur', cont))

  be _parse_new_lr_aux1(count: USize, rule: Rule[S, V], src: Source[S],
    loc: Loc[S], stack: List[_LRRecord[S, V]], recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let self: Parser[S, V] tag = this
    rule._parse(this, src, loc, stack, recur,
      self~_parse_new_lr_aux2(count, rule, src, loc, cont))

  be _parse_new_lr_aux2(count: USize, rule: Rule[S, V], src: Source[S],
    loc: Loc[S], cont: _Cont[S, V], result: Result[S, V],
    stack: List[_LRRecord[S, V]], recur: _LRByRule[S, V])
  =>
    let rec =
      match _LRR[S, V]._get_lr_record(recur, rule, loc)
      | let rec': _LRRecord[S, V] =>
        rec'
      else
        Dbg[S, V]._dbg(stack,
          "_parse_new_lr_aux_{}: CAN'T HAPPEN: NO LR RECORD")
        _LRRecord[S, V](rule, 0, loc, loc, true, None, SetIs[Rule[S, V]])
      end

    match result
    | let success: Success[S, V] // do we need to go on trying to expand?
      if rec.lr and ((count == 0) or (success.next > rec.next))
    =>
      let rec' = _LRRecord[S, V](rec.rule, rec.exp + 1, success.start,
        success.next, true, success, rec.involved)
      let recur' = _LRR[S, V]._set_lr_record(recur, rule, rec')

      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_new_lr_aux2 " + rule.name + ":" +
          rec'.exp.string() + "@" + loc.string() + " #" + count.string() +
          " new expansion: " + success.string())
      end

      let self: Parser[S, V] tag = this
      _memoize(rule, loc, rec'.exp, success,
        self~_parse_new_lr_aux1(count + 1, rule, src, loc, stack, recur',
          cont))
    else // we've failed or we're done expanding
      let stack' = stack.drop(1)
      let recur' = _LRR[S, V]._del_lr_record(recur, rule, loc)

      let res =
        match result
        | let success': Success[S, V] =>
          success'
        | let failure': Failure[S, V] =>
          match rec.res
          | let res': Result[S, V] =>
            res'
          else
            result
          end
        end

      ifdef debug then
        Dbg[S, V]._dbg(stack, "_parse_new_lr_aux2 " + rule.name + ":" +
          rec.exp.string() + "@" + loc.string() + " #" + count.string() +
          " lr DONE: result " + res.string())
      end

      //var foundlr = stack'.exists({(r) => r.involved.contains(rule) })
      var foundlr = false
      for r in stack'.values() do
        if r.involved.contains(rule) then
          foundlr = true
          break
        end
      end
      if not foundlr then
        _memoize(rec.rule, rec.start, rec.exp, res, {() =>
          cont(res, stack', recur')
        })
      else
        cont(res, stack', recur')
      end
    end

  be _memoize(rule: Rule[S, V], loc: Loc[S], exp: USize, result: Result[S, V],
    cont: {()} val)
  =>
    try
      let memo_by_loc =
        try
          _memo(rule)?
        else
          let mbl = _MemoByLoc[S, V]
          _memo.update(rule, mbl)
          mbl
        end

      let memo_by_exp =
        try
          memo_by_loc(loc)?
        else
          let mbe = Array[(Result[S, V] | None)].init(None, exp + 1)
          memo_by_loc.update(loc, mbe)
          mbe
        end

      while memo_by_exp.size() <= exp do
        memo_by_exp.push(None)
      end

      memo_by_exp(exp)? = result
      cont()
    end

  fun _lookup(rule: Rule[S, V], loc: Loc[S], exp: USize)
    : (Result[S, V] | None)
  =>
    try
      let memo_by_loc = _memo(rule)?
      let memo_by_exp = memo_by_loc(loc)?
      memo_by_exp(exp)?
    else
      None
    end


interface val ParseCallback[S, V: Any #share]
  """
  Used to report the results of a parse attempt.
  """
  fun apply(result: Result[S, V])


type _UpdateSeg[S] is (_InsertSeg[S] | _RemoveSeg)


class val _InsertSeg[S]
  let index: USize
  let segment: Segment[S]

  new val create(index': USize, segment': Segment[S]) =>
    index = index'
    segment = segment'


class val _RemoveSeg
  let index: USize

  new val create(index': USize) =>
    index = index'


type _Memo[S, V: Any #share] is
  mut.MapIs[Rule[S, V] tag, _MemoByLoc[S, V]]
type _MemoByLoc[S, V: Any #share] is
  mut.Map[Loc[S], _MemoByExpansion[S, V]]
type _MemoByExpansion[S, V: Any #share] is
  Array[(Result[S, V] | None)]


class val _LRRecord[S, V: Any #share]
  let rule: Rule[S, V]
  let exp: USize
  let start: Loc[S]
  let next: Loc[S]
  let lr: Bool
  let res: (Result[S, V] | None)
  let involved: SetIs[Rule[S, V]]

  new val create(
    rule': Rule[S, V],
    exp': USize,
    start': Loc[S],
    next': Loc[S],
    lr': Bool,
    res': (Result[S, V] | None),
    involved': SetIs[Rule[S, V]] = SetIs[Rule[S, V]])
  =>
    rule = rule'
    exp = exp'
    start = start'
    next = next'
    lr = lr'
    res = res'
    involved = involved'


type _LRByRule[S, V: Any #share] is
  MapIs[Rule[S, V] tag, _LRByLoc[S, V]]
type _LRByLoc[S, V: Any #share] is
  Map[Loc[S], _LRRecord[S, V]]


primitive _LRR[S, V: Any #share]
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


primitive Dbg[S, V: Any #share]
  fun _dbg(stack: List[_LRRecord[S, V]], msg: String) =>
    Debug.out(_dbg_get_indent(stack) + msg)

  fun _dbg_res(result: Result[S, V]): String =>
    match result
    | let success: Success[S, V] =>
      "  => [" + success.start.string() + "," + success.next.string() + ")"
    | let failure: Failure[S, V] =>
      "  => !" + failure.start.string() + ": '" + failure.message + "'"
    end

  fun _dbg_get_indent(stack: List[_LRRecord[S, V]]): String =>
    recover
      var len = stack.size() * 2
      let s = String(len)
      while (len = len - 1) > 0 do
        s.push(' ')
      end
      s
    end
