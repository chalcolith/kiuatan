use "collections"
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
  let _memo_lr: _MemoLR[S, D, V]

  let _stack: Array[_RuleFrame[S, D, V]]

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())
    _updates = _updates.create()
    _memo = _memo.create()
    _memo_lr = _memo_lr.create()
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
    var keys_to_remove = HashSet[_MemoKey[S, D, V], _MemoHash[S, D, V]]
    for (key, result) in _memo.pairs() do
      if key._2.is_in(first) then
        match result
        | let success: Success[S, D, V] =>
          if success.next.is_in(second) then
            keys_to_remove.add(key)
          end
        end
      end
    end
    for key in keys_to_remove.values() do
      try
        _memo.remove(key)?
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

        // this number is derived from empirical testing
        if i >= 100000 then
          // allow garbage collection
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
    if frame.rule.left_recursive then
      _parse_lr(frame, child_result)
    else
      _parse_non_lr(frame, child_result)
    end

  fun ref _parse_non_lr(
    frame: _NamedRuleFrame[S, D, V],
    child_result: (Result[S, D, V] | None))
    : _FrameResult[S, D, V]
  =>
    match child_result
    | None =>
      match try _memo((frame.rule, frame.loc))? end
      | let memoized: Result[S, D, V] =>
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
          " = MEMO FOUND " + memoized.string())
        memoized
      else
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string())
        _call_body(frame)
      end
    | let child_result': Result[S, D, V] =>
      let rule_result =
        match child_result'
        | let success: Success[S, D, V] =>
          Success[S, D, V](frame.rule, success.start, success.next, [ success ])
        | let failure: Failure[S, D, V] =>
          Failure[S, D, V](
            frame.rule,
            failure.start,
            ErrorMsg.rule_expected(frame.rule.name, frame.loc.string()),
            failure)
        end
      if frame.rule.memoize then
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
          " = " + rule_result.string() + "; memoizing")
        _memo((frame.rule, frame.loc)) = rule_result
      else
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
          " = " + rule_result.string())
      end
      rule_result
    end

  fun ref _parse_lr(
    frame: _NamedRuleFrame[S, D, V],
    child_result: (Result[S, D, V] | None))
    : _FrameResult[S, D, V]
  =>
    match child_result
    | None => // new call
      _parse_lr_new_call(frame)
    | let child_result': Result[S, D, V] =>
      _parse_lr_with_child(frame, child_result')
    end

  fun ref _parse_lr_new_call(frame: _NamedRuleFrame[S, D, V])
    : _FrameResult[S, D, V]
  =>
    // look in memo
    match try _memo((frame.rule, frame.loc))? end
    | let memoized: Result[S, D, V] =>
      _Dbg() and _Dbg.out(
        frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
        " = MEMO FOUND " + memoized.string())
      return memoized
    end

    // now see if we're in an LR at this position
    match _get_lr(frame.rule, frame.loc)
    | (let inv: _Involved[S, D, V], let exp: _Expansions[S, D, V]) =>
      try
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
          " = PREV EXPANSION " + (exp.size() - 1).string() + " " +
          exp(exp.size() - 1)?.string())
        return exp(exp.size() - 1)?
      else
        _Dbg() and _Dbg.out(
          frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
          " = FAILURE NO EXPANSIONS!")
        return
          Failure[S, D, V](frame.rule, frame.loc, ErrorMsg.internal_error())
      end
    else
      _Dbg() and _Dbg.out(
        frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
        ": START LR; MEMOIZE EXPANSION ZERO: FAILURE")
      let failure = Failure[S, D, V](
        frame.rule, frame.loc, ErrorMsg._lr_started())
      let expansions = Array[Result[S, D, V]](4)
      expansions.push(failure)
      _save_lr(frame.rule, frame.loc, expansions)
      _call_body(frame)
    end

  fun ref _parse_lr_with_child(
    frame: _NamedRuleFrame[S, D, V],
    child_result: Result[S, D, V])
    : _FrameResult[S, D, V]
  =>
    match _get_lr(frame.rule, frame.loc)
    | (let inv: _Involved[S, D, V], let exp: _Expansions[S, D, V]) =>
      match child_result
      | let cur_success: Success[S, D, V] =>
        let prev_expansion =
          try
            exp(exp.size() - 1)?
          else
            _Dbg() and _Dbg.out(
              frame.depth, "RULE " + frame.rule.name + " @" +
              frame.loc.string() + " FAILURE EXPANSION UNDERFLOW")
            return Failure[S, D, V](
              frame.rule, frame.loc, ErrorMsg.internal_error())
          end
        match prev_expansion
        | let prev_success: Success[S, D, V] =>
          if prev_success.next < cur_success.next then
            // try again
            _Dbg() and _Dbg.out(
              frame.depth, "RULE " + frame.rule.name + " @" +
              frame.loc.string() + " got expansion " +
              exp.size().string() + " = " + cur_success.string() +
              "; trying another expansion")
            exp.push(cur_success)
            _call_body(frame)
          else
            // we're done
            let result = Success[S, D, V](
              frame.rule,
              prev_success.start,
              prev_success.next,
              [ prev_success ])
            _del_lr(frame.rule, frame.loc)
            if frame.rule.memoize then
              _Dbg() and _Dbg.out(
                frame.depth, "RULE " + frame.rule.name + " @" +
                frame.loc.string() + " memozing expansion " +
                exp.size().string() + " = " + result.string())
              _memo((frame.rule, frame.loc)) = result
            else
              _Dbg() and _Dbg.out(
                frame.depth, "RULE " + frame.rule.name + " @" +
                frame.loc.string() + " found expansion " + exp.size().string() +
                " = " + result.string())
            end
            result
          end
        | let prev_failure: Failure[S, D, V] =>
          _Dbg() and _Dbg.out(
            frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
            " got expansion " + exp.size().string() + " = " +
            cur_success.string() + "; trying another expansion")
          exp.push(cur_success)
          _call_body(frame)
        end
      | let failure: Failure[S, D, V] =>
        let result =
          match try exp(exp.size() - 1)? end
          | let prev_success: Success[S, D, V] =>
            _Dbg() and _Dbg.out(
              frame.depth, "RULE " + frame.rule.name + " @" +
              frame.loc.string() + " = " + prev_success.string() +
              " from previous expansion")
            prev_success
          else
            Failure[S, D, V](
              frame.rule,
              frame.loc,
              ErrorMsg.rule_expected(frame.rule.name, frame.loc.string()),
              failure)
          end

        if inv.size() == 1 then
          _Dbg() and _Dbg.out(
            frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
            " = " + result.string() + "; not involved, memoizing")
          _memo((frame.rule, frame.loc)) = result
        else
          _Dbg() and _Dbg.out(
            frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
            " = " + result.string() + "; involved, NOT memoizing")
        end
        _del_lr(frame.rule, frame.loc)
        result
      end
    else
      _Dbg() and _Dbg.out(
        frame.depth, "RULE " + frame.rule.name + " @" + frame.loc.string() +
        " FAILURE ITERATION WITH NO LR RECORD")
      Failure[S, D, V](frame.rule, frame.loc, ErrorMsg.internal_error())
    end

  fun ref _get_lr(rule: NamedRule[S, D, V] box, loc: Loc[S])
    : ((_Involved[S, D, V], _Expansions[S, D, V]) | None)
  =>
    match try _memo_lr(loc)? end
    | let involved: _Involved[S, D, V] =>
      match try involved(rule)? end
      | let expansions: _Expansions[S, D, V] =>
        (involved, expansions)
      end
    end

  fun ref _save_lr(
    rule: NamedRule[S, D, V] box,
    loc: Loc[S],
    expansions: _Expansions[S, D, V])
  =>
    let involved =
      match try _memo_lr(loc)? end
      | let involved': _Involved[S, D, V] =>
        involved'
      else
        let involved' = _Involved[S, D, V]
        _memo_lr(loc) = involved'
        involved'
      end
    involved(rule) = expansions

  fun ref _del_lr(rule: NamedRule[S, D, V] box, loc: Loc[S]) =>
    match try _memo_lr(loc)? end
    | let involved: _Involved[S, D, V] =>
      try involved.remove(rule)? end
    end

  fun _call_body(frame: _NamedRuleFrame[S, D, V]): _FrameResult[S, D, V] =>
    match frame.body
    | let node: RuleNode[S, D, V] box =>
      node.call(frame.depth + 1, frame.loc)
    else
      Failure[S, D, V](
        frame.rule, frame.loc, ErrorMsg.rule_empty(frame.rule.name))
    end
