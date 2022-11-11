use per = "collections/persistent"

actor Parser[S, D: Any #share = None, V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior
  parses. Used to initiate a parse attempt.
  """

  var _segments: per.List[Segment[S]]
  var _updates: Array[_SegmentUpdate[S]]

  let _memo: _Memo[S, D, V]

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())
    _updates = Array[_SegmentUpdate[S]]
    _memo = _Memo[S, D, V]

  fun num_segments(): USize =>
    """
    Returns the number of segments currently in the source.
    """
    _segments.size()

  be insert_segment(index: USize, segment: Segment[S]) =>
    """
    Insert a source segment at the given index.  The insertion will happen upon the next call to `parse()`.
    """
    _updates.push(_InsertSeg[S](index, segment))

  be remove_segment(index: USize) =>
    """
    Removes the source segment at the given index.  The removal will happen upon the next call to `parse()`.
    """
    _updates.push(_RemoveSeg(index))

  fun ref _update_segments() =>
    for op in _updates.values() do
      match op
      | let insert: _InsertSeg[S] =>
        if insert.index > 0 then
          try
            _remove_memoized_spanning(
              _segments(insert.index - 1)?,
              _segments(insert.index)?)
          end
        end

        let left = _segments.take(insert.index)
        let right = _segments.drop(insert.index)
        _segments = left
          .concat(per.Cons[Segment[S]](insert.segment, per.Nil[Segment[S]]))
          .concat(right)
      | let remove: _RemoveSeg =>
        try
          if remove.index > 0 then
            _remove_memoized_spanning(
              _segments(remove.index - 1)?,
              _segments(remove.index)?)
          end
          _remove_memoized_spanning(
            _segments(remove.index)?,
            _segments(remove.index)?)
          _remove_memoized_spanning(
            _segments(remove.index)?,
            _segments(remove.index + 1)?
          )
        end

        let left = _segments.take(remove.index)
        let right = _segments.take(remove.index + 1)
        _segments = left.concat(right)
      end
    end
    _updates.clear()

  fun ref _remove_memoized_spanning(first: Segment[S], second: Segment[S]) =>
    // removes memoized results that span the first and second segments
    for memo_by_loc in _memo.values() do
      var keys_to_remove = per.Set[Loc[S]]
      for (loc, result) in memo_by_loc.pairs() do
        if loc.is_in(first) then
          match result
          | let success: Success[S, D, V] =>
            if success.next.is_in(second) then
              keys_to_remove = keys_to_remove.add(loc)
            end
          else
            keys_to_remove = keys_to_remove.add(loc)
          end
        end
      end
      for key in keys_to_remove.values() do
        try memo_by_loc.remove(key)? end
      end
    end

  be parse(
    rule: RuleNode[S, D, V] val,
    data: D,
    callback: ParseCallback[S, D, V],
    start: (Loc[S] | None) = None,
    clear_memo: Bool = false)
  =>
    """
    Initiates a parse attempt with the given rule.
    """
    if clear_memo then
      _memo.clear()
    end

    match _segments
    | let source: per.Cons[Segment[S]] =>
      _update_segments()
      let loc: Loc[S] =
        match start
        | let loc': Loc[S] =>
          loc'
        else
          Loc[S](source, 0)
        end

      let state = _ParseState[S, D, V](this, data, source)
      rule.parse(consume state, 0, loc,
        {(state': _ParseState[S, D, V], result: Result[S, D, V]) =>
          match result
          | let success: Success[S, D, V] =>
            callback(success, success._values())
          else
            callback(result, Array[V])
          end
        })
    else
      let loc =
        match start
        | let loc': Loc[S] =>
          loc'
        else
          Loc[S](per.Cons[Segment[S]]([], per.Nil[Segment[S]]), 0)
        end
      callback(
        Failure[S, D, V](rule, loc, data, ErrorMsg.empty_source()), Array[V])
    end

  be _parse_named_rule(
    rule: NamedRule[S, D, V],
    body: RuleNode[S, D, V],
    state: _ParseState[S, D, V],
    depth: USize,
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this

    // look in memo for a top-level memoized result
    match _lookup(rule, loc, 0)
    | let result: Result[S, D, V] =>
      ifdef debug then
        _Dbg.out(depth + 1, "found " + rule.name + "::0")
      end
      cont(consume state, result)
      return
    end

    // if we can't be left-recursive, go ahead and parse
    if not rule.might_recurse(per.Lists[RuleNode[S, D, V] tag].empty()) then
      body.parse(consume state, depth + 1, loc,
        {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
          ifdef debug then
            _Dbg.out(
              depth + 2,
              "memoizing " + rule.name + "::0 " + result'.string())
          end
          self._memoize(consume state', rule, loc, result', cont)
        })
      return
    end

    // look in the LR records to see if we're in an LR
    match state.existing_lr_state(rule, depth, loc)
    | let result: Result[S, D, V] =>
      cont(consume state, result)
      return
    end

    // otherwise, memoize this rule as having failed for this expansion
    // and try parsing
    let failure = Failure[S, D, V](rule, loc, state.data)
    ifdef debug then
      _Dbg.out(depth + 1, rule.name + "::1")
      _Dbg.out(depth + 2, "expansion " + rule.name + "::1 " + failure.string())
    end

    let lr_index = state.push_state(rule, loc, failure)
    body.parse(consume state, depth + 2, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        let exp = state'.cur_exp(lr_index)
        ifdef debug then
          _Dbg.out(depth + 2, "expansion " + rule.name + "::" +
            exp.string() + " " + result'.string())
        end
        state'.push_result(lr_index, result')

        match result'
        | let success: Success[S, D, V] =>
          // if we've detected left-recursion, and our result is bigger than
          // the last expansion, start another expansion
          if state'.lr_detected(lr_index) and
            (success.next > state'.next(lr_index))
          then
            self._parse_named_rule(rule, body, consume state', depth, loc, cont)
            return
          elseif lr_index == 0 then
            // we're at the top level; memoize everything
            let to_memoize = state'.cleanup(depth)
            self._memoize_seq(consume state', to_memoize, result', cont)
            return
          end
        | let failure: Failure[S, D, V] =>
          if lr_index == 0 then
            // we're at the top level; memoize everything
            let to_memoize = state'.cleanup(depth)
            self._memoize_seq(consume state', to_memoize, result', cont)
            return
          end
        end
        cont(consume state', result')
      })

  fun _lookup(rule: NamedRule[S, D, V], loc: Loc[S], exp: USize)
    : (Result[S, D, V] | None)
  =>
    try
      _memo(rule)?(loc)?
    end

  be _memoize(
    state: _ParseState[S, D, V],
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    result: Result[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    let by_loc =
      try
        _memo(rule)?
      else
        let by_loc' = _MemoByLoc[S, D, V]
        _memo(rule) = by_loc'
        by_loc'
      end
    by_loc(loc) = result
    cont(consume state, result)

  be _memoize_seq(
    state: _ParseState[S, D, V],
    results: ReadSeq[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] val,
    result: Result[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    for (rule, loc, res) in results.values() do
      let by_loc =
        try
          _memo(rule)?
        else
          let by_loc' = _MemoByLoc[S, D, V]
          _memo(rule) = by_loc'
          by_loc'
        end
      by_loc(loc) = res
    end
    cont(consume state, result)
