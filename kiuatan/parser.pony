
use per = "collections/persistent"

actor Parser[S, D: Any #share = None, V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior parses.
  Also used to initiate a parse attempt.
  """

  var _segments: per.List[Segment[S]]
  var _updates: per.List[_SegmentUpdate[S]]
    = per.Lists[_SegmentUpdate[S]].empty()

  let _memo: _Memo[S, D, V] = _memo.create()

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())

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
    _updates = _updates.concat(
      per.Cons[_SegmentUpdate[S]](insert, per.Nil[_SegmentUpdate[S]]))

  be remove_segment(index: USize) =>
    """
    Removes the source segment at the given index.  The removal will happen upon the next call to `parse()`.
    """
    let remove = _RemoveSeg(index)
    _updates = _updates.concat(
      per.Cons[_SegmentUpdate[S]](remove, per.Nil[_SegmentUpdate[S]]))

  fun ref _update_segments() =>
    for op in _updates.values() do
      match op
      | let insert: _InsertSeg[S] =>
        let left = _segments.take(insert.index)
        let right = _segments.drop(insert.index)
        _segments = left
          .concat(per.Cons[Segment[S]](insert.segment, per.Nil[Segment[S]]))
          .concat(right)
      | let remove: _RemoveSeg =>
        let left = _segments.take(remove.index)
        let right = _segments.take(remove.index + 1)
        _segments = left.concat(right)
      end
    end
    _updates = per.Lists[_SegmentUpdate[S]].empty()

  be parse(rule: RuleNode[S, D, V], data: D, callback: ParseCallback[S, D, V],
    start: (Loc[S] | None) = None, clear_memo: Bool = false)
  =>
    """
    Initiates a parse attempt with the given rule.
    """
    if clear_memo then
      _memo.clear()
    end

    let stack = per.Lists[_LRRecord[S, D, V]].empty()
    let recur = _LRByRule[S, D, V]

    match _segments
    | let source: per.Cons[Segment[S]] =>
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
          {(result: Result[S, D, V], stack: _LRStack[S, D, V],
            recur: _LRByRule[S, D, V])
          =>
            match result
            | let success: Success[S, D, V] =>
              callback(result, success._values())
            else
              callback(result, recover val Array[V] end)
            end
          }
        end
      _parse_with_memo(rule, source, start', data, stack, recur, consume cont)
    else
      let pos =
        match start
        | let loc: Loc[S] =>
          loc
        else
          Loc[S](per.Cons[Segment[S]]([], per.Nil[Segment[S]]), 0)
        end
      callback(Failure[S, D, V](rule, pos, data, ErrorMsg.empty_source()),
        recover val Array[V] end)
    end

  be _parse_with_memo(
    node: RuleNode[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    match node
    | let rule: NamedRule[S, D, V] =>
      let is_terminal = rule.is_terminal()
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_with_memo: " + rule.name + "@" +
          loc.string() + ": " +
          (if is_terminal then "terminal" else "nonterminal" end))
      end

      match _lookup(rule, loc, 0)
      | let result: Result[S, D, V] =>
        ifdef debug then
          _Dbg[S, D, V]._dbg(stack, "_parse_with_memo: " + rule.name + "@" +
            loc.string() + ": from memo: " + result.string())
        end
        cont(result, stack, recur)
      else
        if is_terminal then
          _parse_non_lr(rule, src, loc, data, stack, recur, cont)
        else
          ifdef debug then
            _Dbg[S, D, V]._dbg(stack, "_parse_with_memo: calling parse_lr: " + rule.name + "@" + loc.string())
          end

          _parse_lr(rule, src, loc, data, stack, recur, cont)
        end
      end
    else
      node.parse(this, src, loc, data, stack, recur, cont)
    end

  fun _parse_non_lr(
    rule: NamedRule[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    let stack' = stack.prepend(_LRRecord[S, D, V](rule, 0, loc, loc, false, None))
    let parser: Parser[S, D, V] = this
    rule.parse(this, src, loc, data, stack', recur,
      {(result: Result[S, D, V], stack'': _LRStack[S, D, V],
        recur': _LRByRule[S, D, V])(cont)
      =>
        ifdef debug then
          _Dbg[S, D, V]._dbg(stack'', "_parse_non_lr: " + rule.name + ":0@" +
            loc.string() + ": " + result.string())
        end
        parser._memoize(rule, loc, 0, result, {() =>
          cont(result, stack''.drop(1), recur')
        })
      })

  fun _parse_lr(
    rule: NamedRule[S, D, V],
    src: Source[S],
    loc: Loc[S],
    data: D,
    stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    match _LRRecords[S, D, V]._get_lr_record(recur, rule, loc)
    | let rec: _LRRecord[S, D, V] =>
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_lr: got record: " + rec.rule.name + ":"
          + rec.exp.string() + "@" + rec.start.string()
          + " calling _parse_existing_lr")
      end
      _parse_existing_lr(rule, rec, data, stack, recur, cont)
    else
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_lr: no LR record for " + rule.name
          + "@" + loc.string())
      end
      _parse_new_lr(rule, src, loc, data, stack, recur, cont)
    end

  fun _parse_existing_lr(rule: NamedRule[S, D, V], rec: _LRRecord[S, D, V],
    data: D, stack: _LRStack[S, D, V], recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    var involved = rec.involved
    for lr in stack.reverse().values() do
      if lr.rule is rule then break end
      involved = involved.add(rule)
    end
    match _lookup(rule, rec.start, rec.exp)
    | let success: Success[S, D, V] =>
      let rec' = _LRRecord[S, D, V](rec.rule, rec.exp, rec.start, success.next,
        true, success, involved)
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec'.exp.string() + "@[" + rec'.start.string() + "," +
          rec'.next.string() + "): result " + success.string())
      end
      cont(success, stack, _LRRecords[S, D, V]._set_lr_record(recur, rule, rec'))
    | let failure: Failure[S, D, V] =>
      let rec' = _LRRecord[S, D, V](rec.rule, rec.exp, rec.start, rec.start,
        true, failure, involved)
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec'.exp.string() + "@" + rec'.start.string() + ": result " +
          failure.string())
      end
      cont(failure, stack, _LRRecords[S, D, V]._set_lr_record(recur, rule, rec'))
    else // can't happen
      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_existing_lr: " + rule.name + ":" +
          rec.exp.string() + "@" + rec.start.string() +
          ": FAILED; CAN'T HAPPEN")
      end
      cont(Failure[S, D, V](rule, rec.start, data,
        ErrorMsg._lr_not_memoized()), stack, recur)
    end

  fun _parse_new_lr(rule: NamedRule[S, D, V], src: Source[S], loc: Loc[S],
    data: D, stack: _LRStack[S, D, V], recur: _LRByRule[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    let rec' = _LRRecord[S, D, V](rule, 1, loc, loc, false, None,
      _InvolvedSet[S, D, V])
    let stack' = stack.prepend(rec')
    let recur' = _LRRecords[S, D, V]._set_lr_record(recur, rule, rec')

    ifdef debug then
      _Dbg[S, D, V]._dbg(stack', "_parse_new_lr: memoize " + rule.name + ":" +
        rec'.exp.string() + "@" + loc.string() + " failure")
    end

    let self: Parser[S, D, V] = this
    _memoize(rule, loc, rec'.exp,
      Failure[S, D, V](rule, loc, data, ErrorMsg._lr_started()),
      self~_parse_new_lr_aux1(0, rule, src, loc, data, stack', recur', cont))

  be _parse_new_lr_aux1(count: USize, rule: NamedRule[S, D, V], src: Source[S],
    loc: Loc[S], data: D, stack: _LRStack[S, D, V],
    recur: _LRByRule[S, D, V], cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] = this
    rule.parse(this, src, loc, data, stack, recur,
      self~_parse_new_lr_aux2(count, rule, src, loc, data, cont))

  be _parse_new_lr_aux2(count: USize, rule: NamedRule[S, D, V], src: Source[S],
    loc: Loc[S], data: D, cont: _Continuation[S, D, V], result: Result[S, D, V],
    stack: _LRStack[S, D, V], recur: _LRByRule[S, D, V])
  =>
    let rec =
      match _LRRecords[S, D, V]._get_lr_record(recur, rule, loc)
      | let rec': _LRRecord[S, D, V] =>
        rec'
      else
        ifdef debug then
          _Dbg[S, D, V]._dbg(stack,
            "_parse_new_lr_aux_{}: CAN'T HAPPEN: NO LR RECORD")
        end
        _LRRecord[S, D, V](rule, 0, loc, loc, true, None, _InvolvedSet[S, D, V])
      end

    ifdef debug then
      _Dbg[S, D, V]._dbg(stack, "_parse_new_lr_aux2 " + rule.name + ":" +
        rec.exp.string() + "@[" + loc.string() +"," + rec.next.string() +
        ") #" + count.string() + " LR " + rec.lr.string())

      match result
      | let success: Success[S, D, V] =>
        _Dbg[S, D, V]._dbg(stack, "                   success@[" +
          success.start.string() + "," + success.next.string() + ") " +
          "success.next > rec.next " + (success.next > rec.next).string())
      end
    end

    match result
    | let success: Success[S, D, V] // do we need to go on trying to expand?
      if rec.lr and ((count == 0) or (success.next > rec.next))
    =>
      let rec' = _LRRecord[S, D, V](rec.rule, rec.exp + 1, success.start,
        success.next, true, success, rec.involved)
      let recur' = _LRRecords[S, D, V]._set_lr_record(recur, rule, rec')

      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_new_lr_aux2 " + rule.name + ":" +
          rec'.exp.string() + "@" + loc.string() + " #" + count.string() +
          " new expansion: " + success.string())
      end

      let self: Parser[S, D, V] = this
      _memoize(rule, loc, rec'.exp, success,
        self~_parse_new_lr_aux1(count + 1, rule, src, loc, data, stack, recur',
          cont))
    else // we've failed or we're done expanding
      let stack' = stack.drop(1)
      let recur' = _LRRecords[S, D, V]._del_lr_record(recur, rule, loc)

      let res =
        match rec.res
        | let res': Result[S, D, V] =>
          res'
        else
          result
        end

      ifdef debug then
        _Dbg[S, D, V]._dbg(stack, "_parse_new_lr_aux2 " + rule.name + ":" +
          rec.exp.string() + "@" + loc.string() + " #" + count.string() +
          " lr DONE: result " + res.string())
      end

      var foundlr = stack'.exists({(r) => r.involved.contains(rule) })
      if not foundlr then
        _memoize(rec.rule, rec.start, rec.exp, res, {() =>
          cont(res, stack', recur')
        })
      else
        cont(res, stack', recur')
      end
    end

  be _memoize(rule: NamedRule[S, D, V], loc: Loc[S], exp: USize,
    result: Result[S, D, V], cont: {()} val)
  =>
    try
      let memo_by_loc =
        try
          _memo(rule)?
        else
          let mbl = _MemoByLoc[S, D, V]
          _memo.update(rule, mbl)
          mbl
        end

      let memo_by_exp =
        try
          memo_by_loc(loc)?
        else
          let mbe = Array[(Result[S, D, V] | None)].init(None, exp + 1)
          memo_by_loc.update(loc, mbe)
          mbe
        end

      while memo_by_exp.size() <= exp do
        memo_by_exp.push(None)
      end

      memo_by_exp(exp)? = result
      cont()
    end

  fun _lookup(rule: NamedRule[S, D, V], loc: Loc[S], exp: USize)
    : (Result[S, D, V] | None)
  =>
    try
      let memo_by_loc = _memo(rule)?
      let memo_by_exp = memo_by_loc(loc)?
      memo_by_exp(exp)?
    else
      None
    end

interface val ParseCallback[S, D: Any #share, V: Any #share]
  """
  Used to report the results of a parse attempt.
  """
  fun apply(result: Result[S, D, V], values: ReadSeq[V] val)
