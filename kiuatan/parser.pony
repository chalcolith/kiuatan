use per = "collections/persistent"

actor Parser[S, D: Any #share = None, V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior
  parses. Used to initiate a parse attempt.
  """

  var _segments: per.List[Segment[S]]
  var _updates: Array[_SegmentUpdate[S]]

  let _memo: _Memo[S, D, V] = _memo.create()

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())
    _updates = Array[_SegmentUpdate[S]]

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
      let keys_to_remove = Array[Loc[S]]
      for loc_and_exps in memo_by_loc.pairs() do
        if loc_and_exps._1.is_in(first) then
          let exp: Array[Result[S, D, V]] = loc_and_exps._2
          try
            match exp(exp.size() - 1)?
            | let success: Success[S, D, V] =>
              if success.next.is_in(second) then
                keys_to_remove.push(loc_and_exps._1)
              end
            end
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
    body.parse(consume state, depth + 1, loc, cont)
