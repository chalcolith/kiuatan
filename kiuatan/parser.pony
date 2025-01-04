use col = "collections"
use per = "collections/persistent"

use "debug"

actor Parser[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior
  parses. Used to initiate a parse attempt.
  """

  var _segments: Source[S]
  var _updates: Array[_SegmentUpdate[S]]

  let _memo: _Memo[S, D, V]
  let _lr_states:
    col.HashMap[
      (NamedRule[S, D, V] box, Loc[S]),
      _LRRuleState[S, D, V],
      _LRRuleLocHash[S, D, V]
    ]

  let _stack: Array[_RuleFrame[S, D, V]]

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())
    _updates = _updates.create()
    _memo = _memo.create()
    _lr_states = _lr_states.create()
    _stack = _stack.create(1024)

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
          if _segments.size() > (remove.index + 1) then
            _remove_memoized_spanning(
              _segments(remove.index)?,
              _segments(remove.index + 1)?)
          end
        end

        let left = _segments.take(remove.index)
        let right = _segments.drop(remove.index + 1)
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

    _update_segments()

    match _segments
    | let source: per.Cons[Segment[S]] =>
      let loc: Loc[S] =
        match start
        | let loc': Loc[S] =>
          loc'
        else
          Loc[S](source, 0)
        end

      _stack.clear()
      _stack.push(rule.call(0, loc))
      _parse(rule, loc, data, callback)
    else
      let loc =
        match start
        | let loc': Loc[S] =>
          loc'
        else
          Loc[S](per.Cons[Segment[S]]([], per.Nil[Segment[S]]), 0)
        end
      let failure = Failure[S, D, V](rule, loc, ErrorMsg.empty_source())
      callback(failure, [])
    end

  be _parse(
    top_rule: RuleNode[S, D, V] val,
    top_start: Loc[S],
    data: D,
    callback: ParseCallback[S, D, V])
  =>
    var last_child_result: (Result[S, D, V] | None) = None
    var i: USize = 0
    while true do
      i = i + 1

      let frame =
        try
          _stack(_stack.size() - 1)?
        else
          let failure = Failure[S, D, V](
            top_rule, top_start, ErrorMsg.internal_error())
          callback(failure, [])
          return
        end

      let frame_result =
        match frame
        | let named_rule_frame: _NamedRuleFrame[S, D, V] =>
          _parse_named_rule(named_rule_frame, last_child_result)
        | let rule_frame: _RuleFrame[S, D, V] =>
          rule_frame.run(last_child_result)
        end

      match frame_result
      | let result: Result[S, D, V] =>
        last_child_result = result
        if _stack.size() == 1 then
          match result
          | let success: Success[S, D, V] =>
            callback(success, success._values(data))
          else
            callback(result, [])
          end
          return
        else
          try _stack.pop()? end
        end
      | let rule_frame: _RuleFrame[S, D, V] =>
        last_child_result = None
        _stack.push(rule_frame)

        if i >= 100 then
          _parse(top_rule, top_start, data, callback)
          return
        end
      end
    end

  fun ref _parse_named_rule(
    frame: _NamedRuleFrame[S, D, V],
    child_result: (Result[S, D, V] | None))
    : _FrameResult[S, D, V]
  =>
    // look in the memo
    match _lookup(frame.depth, frame.rule, frame.loc)
    | let result: Result[S, D, V] =>
      _Dbg() and _Dbg.out(
        frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
        "= MEMO FOUND " + result.string())
      return result
    end

    // if we have a result, check if it is an LR expansion
    // if so, try again; if not, return the result
    match child_result
    | let result: Result[S, D, V] =>
      if _lr_detected(frame.rule, frame.loc) then
        (_, let topmost) = _current_expansion(frame.rule, frame.loc)

        match result
        | let success: Success[S, D, V] =>
          let last_next = _last_next(frame.rule, frame.loc)
          if success.next > last_next then
            // try another expansion
            _remove_expansions_below(frame.depth, frame.loc)

            let result' = Success[S, D, V](
              frame.rule, success.start, success.next, [ success ])
            _push_expansion(frame.depth, frame.rule, frame.loc, result')

            _Dbg() and _Dbg.out(
              frame.depth, "= #" +
              _current_expansion(frame.rule, frame.loc)._1.string() + " " +
              result'.string())

            return _call_body(frame)
          end
        | let failure: Failure[S, D, V] =>
          // fall through; if there's no previous expansion then we'll fail
          None
        end

        // we're done expanding; continue with the greediest expansion
        let result' =
          match _prev_expansion(frame.rule, frame.loc)
          | (let result'': Result[S, D, V], _) =>
            result''
          else
            Failure[S, D, V](
              frame.rule,
              frame.loc,
              ErrorMsg.rule_expected(frame.rule.name, frame.loc.string()))
          end

        if topmost then
          // we're at the top level of left-recursion; memoize us and all rules
          // below us, then remove all LR records
          let to_memoize = _remove_expansions_below(0, frame.loc)
          to_memoize.push((frame.rule, frame.loc, result'))
          _memoize_seq(frame.depth, to_memoize, result')
        else
          _update_expansion(frame.depth, frame.rule, frame.loc, result')
        end

        _Dbg() and _Dbg.out(frame.depth, "= " + result'.string())
        return result'
      else
        let result' =
          match result
          | let success: Success[S, D, V] =>
            Success[S, D, V](
              frame.rule, success.start, success.next, [ success ])
          | let failure: Failure[S, D, V] =>
            Failure[S, D, V](
              frame.rule,
              failure.start,
              ErrorMsg.rule_expected(frame.rule.name, failure.start.string()),
              failure)
          end

        if frame.rule.memoize then
          var involved = false
          for lr_state in _lr_states.values() do
            if frame.loc == lr_state.loc then
              involved = true
              break
            end
          end

          if involved then
            _memoize_in_lr(frame.depth, frame.rule, frame.loc, result')
          else
            _memoize(frame.depth, frame.rule, frame.loc, result')
          end
        end

        _Dbg() and _Dbg.out(frame.depth, "= " + result'.string())
        return result'
      end
    end

    _Dbg() and _Dbg.out(
      frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
      if frame.rule.left_recursive then " LR" else "" end +
      if frame.rule.memoize then " m" else "" end)

    // if we can't be left-recursive then parse normally
    if not frame.rule.left_recursive then
      return _call_body(frame)
    end

    // look in the LR rules to see if we have a previous expansion
    match _prev_expansion(frame.rule, frame.loc, true)
    | (let result: Result[S, D, V], let first_lr: Bool) =>
      ifdef debug then
        if first_lr then
          _Dbg() and _Dbg.out(
            frame.depth + 1, frame.rule.name + ": LR DETECTED")
        end
        let prev_exp = _current_expansion(frame.rule, frame.loc)._1 - 1
        _Dbg() and _Dbg.out(
          frame.depth + 1, " fnd_exp " + frame.rule.name + "@" +
          frame.loc.string() + " <" + prev_exp.string() + "> " +
          result.string())
      end
      return result
    end

    // otherwise, memoize this rule as having failed for this expansion
    // and try parsing again
    let failure = Failure[S, D, V](frame.rule, frame.loc)
    _push_expansion(frame.depth, frame.rule, frame.loc, failure)

    _Dbg() and _Dbg.out(
      frame.depth + 1, frame.rule.name + "@" + frame.loc.string() + " <" +
      _current_expansion(frame.rule, frame.loc)._1.string() + ">")
    _call_body(frame)

  fun _call_body(frame: _NamedRuleFrame[S, D, V]): _FrameResult[S, D, V] =>
    match frame.body
    | let node: RuleNode[S, D, V] =>
      node.call(frame.depth + 1, frame.loc)
    else
      Failure[S, D, V](
        frame.rule, frame.loc, ErrorMsg.rule_empty(frame.rule.name))
    end

  fun _lookup(depth: USize, rule: NamedRule[S, D, V] box, loc: Loc[S])
    : (Result[S, D, V] | None)
  =>
    try
      let result = _memo(rule)?(loc)?
      _Dbg() and _Dbg.out(depth, "found " + rule.name + " " + result.string())
      result
    end

  fun ref _memoize(
    depth: USize,
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    _Dbg() and _Dbg.out(
      depth, " memoize " + rule.name + "@" + loc.string() + " " +
      result.string())

    let by_loc =
      try
        _memo(rule)?
      else
        let by_loc' = _MemoByLoc[S, D, V]
        _memo(rule) = by_loc'
        by_loc'
      end
    by_loc(loc) = result

  fun ref _memoize_seq(
    depth: USize,
    results: ReadSeq[(NamedRule[S, D, V] box, Loc[S], Result[S, D, V])],
    result: Result[S, D, V])
  =>
    for (rule, loc, res) in results.values() do
      if not rule.memoize then
        continue
      end

      _Dbg() and _Dbg.out(
        depth, " memoize(seq) " + rule.name + " " + res.string())

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

  fun ref _memoize_in_lr(
    depth: USize,
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    _push_expansion(depth, rule, loc, result)

  fun ref _push_expansion(
    depth: USize,
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    let toplevel = _lr_states.size() == 0
    try
      let lr_state = _lr_states((rule, loc))?
      let cur_exp = lr_state.expansions.size()
      _Dbg() and _Dbg.out(
        depth, " mem_exp " + rule.name + "@" + loc.string() + " <" +
        cur_exp.string() + "> " + result.string())
      lr_state.expansions.push(result)
    else
      let lr_state = _LRRuleState[S, D, V](depth, rule, loc, toplevel)
      let cur_exp = lr_state.expansions.size()
      _Dbg() and _Dbg.out(
        depth, " mem_exp " + rule.name + "@" + loc.string() + " <" +
        cur_exp.string() + "> " + result.string())
      lr_state.expansions.push(result)
      _lr_states((rule, loc)) = lr_state
    end

  fun ref _update_expansion(
    depth: USize,
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    try
      let lr_state = _lr_states((rule, loc))?
      let prev_exp = lr_state.expansions.size() - 1
      _Dbg() and _Dbg.out(
        depth, " mem_upd " + rule.name + "@" + loc.string() + " <" +
        prev_exp.string() + "> " + result.string())
      lr_state.expansions(prev_exp)? = result
    end

  fun _current_expansion(rule: NamedRule[S, D, V] box, loc: Loc[S])
    : (USize, Bool) =>
    try
      let lr_state = _lr_states((rule, loc))?
      (lr_state.expansions.size(), lr_state.topmost)
    else
      (0, false)
    end

  fun ref _remove_expansions(rule: NamedRule[S, D, V] box, loc: Loc[S]) =>
    try
      _lr_states.remove((rule, loc))?
    end

  fun ref _remove_expansions_below(depth: USize, loc: Loc[S])
    : Array[(NamedRule[S, D, V] box, Loc[S], Result[S, D, V])]
  =>
    let to_memoize = Array[(NamedRule[S, D, V] box, Loc[S], Result[S, D, V])]
    let to_remove = Array[(NamedRule[S, D, V] box, Loc[S])]
    for lr_state in _lr_states.values() do
      if (lr_state.depth >= depth) and (lr_state.loc == loc) then
        let last_exp = lr_state.expansions.size() - 1
        try
          to_memoize.push(
            (lr_state.rule, lr_state.loc, lr_state.expansions(last_exp)?))
          to_remove.push((lr_state.rule, lr_state.loc))
        end
      end
    end
    for key in to_remove.values() do
      try
        _lr_states.remove(key)?
      end
    end
    to_memoize

  fun ref _prev_expansion(
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    detect_lr: Bool = false)
    : ((Result[S, D, V], Bool) | None)
  =>
    try
      let lr_state = _lr_states((rule, loc))?
      let first_detected = not lr_state.lr_detected
      if detect_lr then
        lr_state.lr_detected = true
      end
      let prev_exp = lr_state.expansions.size() - 1
      let result = lr_state.expansions(prev_exp)?
      (result, first_detected)
    end

  fun _lr_detected(rule: NamedRule[S, D, V] box, loc: Loc[S]): Bool =>
    try
      _lr_states((rule, loc))?.lr_detected
    else
      false
    end

  fun _last_next(rule: NamedRule[S, D, V] box, loc: Loc[S]): Loc[S] =>
    try
      let lr_state = _lr_states((rule, loc))?
      let prev_exp = lr_state.expansions.size() - 1
      match lr_state.expansions(prev_exp)?
      | let success: Success[S, D, V] =>
        return success.next
      | let failure: Failure[S, D, V] =>
        return failure.start
      end
    end
    Loc[S](_segments)
