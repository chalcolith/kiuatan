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
    state: _ParseState[S, D, V],
    depth: USize,
    rule: NamedRule[S, D, V],
    body: RuleNode[S, D, V],
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this

    // look in memo for a top-level memoized result
    match _lookup(depth + 1, rule, loc)
    | let result: Result[S, D, V] =>
      cont(consume state, result)
      return
    end

    // if we can't be left-recursive, go ahead and parse
    if not rule.might_recurse(per.Lists[RuleNode[S, D, V] tag].empty()) then
      body.parse(consume state, depth + 1, loc,
        {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
          self._memoize(consume state', depth + 1, rule, loc, result', cont)
        })
      return
    end

    // look in the LR records to see if we have a previous expansion
    match state.prev_expansion(rule, loc, true)
    | (let result: Result[S, D, V], let first_lr: Bool) =>
      ifdef debug then
        if first_lr then
          _Dbg.out(depth + 1, rule.name + ": LR DETECTED")
        end
        let prev_exp = state.current_expansion(rule, loc) - 1
        _Dbg.out(depth + 1, "fnd_exp " + rule.name + "@" + loc.string() + " <" +
          prev_exp.string() + "> " + result.string())
      end
      cont(consume state, result)
      return
    end

    // otherwise, memoize this rule as having failed for this expansion
    // and try parsing
    let failure = Failure[S, D, V](rule, loc, state.data)
    let topmost = state.push_expansion(depth + 1, rule, loc, failure)

    ifdef debug then
      _Dbg.out(depth + 1, rule.name + "@" + loc.string() + " <" +
        state.current_expansion(rule, loc).string() + ">")
    end
    _try_expansion(consume state, depth, rule, body, loc, topmost, cont)

  be _try_expansion(
    state: _ParseState[S, D, V],
    depth: USize,
    rule: NamedRule[S, D, V],
    body: RuleNode[S, D, V],
    loc: Loc[S],
    topmost: Bool,
    cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this

    body.parse(consume state, depth + 2, loc,
      {(state': _ParseState[S, D, V], result': Result[S, D, V]) =>
        if state'.lr_detected(rule, loc) then
          let cur_exp = state'.current_expansion(rule, loc)

          match result'
          | let success: Success[S, D, V] =>
            let last_next = state'.last_next(rule, loc)
            if success.next > last_next then
              // try another expansion
              state'.remove_expansions_below(depth + 2, loc)
              state'.push_expansion(depth + 2, rule, loc, success)

              ifdef debug then
                _Dbg.out(depth + 1, rule.name + "@" + loc.string() + " <" +
                  state'.current_expansion(rule, loc).string() + ">")
              end
              self._try_expansion(
                consume state',
                depth,
                rule,
                body,
                loc,
                topmost,
                cont)
              return
            end
            // fall through
          end

          // we're done; continue with the last expansion
          let result'' =
            match state'.prev_expansion(rule, loc)
            | (let r: Result[S, D, V], _) =>
              r
            else
              result'
            end

          if topmost then
            // we're at the top level; memoize us and remove all LR records
            state'.remove_expansions_below(0, loc)
            self._memoize(consume state', depth + 1, rule, loc, result'', cont)
          else
            // we're not at the top level; update our expansion but remove below
            state'.update_expansion(depth + 1, rule, loc, result'')
            cont(consume state', result'')
          end
        elseif topmost then
          state'.remove_expansions_below(0, loc)
          self._memoize(consume state', depth + 1, rule, loc, result', cont)
        else
          state'.update_expansion(depth + 1, rule, loc, result')
          cont(consume state', result')
        end
      })

  fun _lookup(depth: USize, rule: NamedRule[S, D, V], loc: Loc[S])
    : (Result[S, D, V] | None)
  =>
    try
      let result = _memo(rule)?(loc)?

      ifdef debug then
        _Dbg.out(depth, "found " + rule.name + " " + result.string())
      end

      result
    end

  be _memoize(
    state: _ParseState[S, D, V],
    depth: USize,
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    result: Result[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    ifdef debug then
      _Dbg.out(depth, "memoize " + rule.name + " " + result.string())
    end

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
    depth: USize,
    results: ReadSeq[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] val,
    result: Result[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    for (rule, loc, res) in results.values() do
      ifdef debug then
        _Dbg.out(depth, "memoize " + rule.name + " " + res.string())
      end

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
