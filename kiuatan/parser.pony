use col = "collections"
use per = "collections/persistent"

use "debug"

actor Parser[S, D: Any #share = None, V: Any #share = None]
  """
  Stores a source of inputs to a parse, and a memo of parse results from prior
  parses. Used to initiate a parse attempt.
  """

  var _segments: Source[S]
  var _updates: Array[_SegmentUpdate[S]]

  let _memo: _Memo[S, D, V]
  let _disj_results:
    col.MapIs[_DisjInstance, Array[(Result[S, D, V] | None)]]

  let _left_recursive_rules: per.MapIs[NamedRule[S, D, V] val, Bool]
  let _lr_states:
    col.HashMap[
      (NamedRule[S, D, V] val, Loc[S]),
      _LRRuleState[S, D, V],
      _LRRuleLocHash[S, D, V]
    ]

  new create(source: ReadSeq[Segment[S]] val) =>
    _segments = per.Lists[Segment[S]].from(source.values())
    _updates = _updates.create()
    _memo = _memo.create()
    _disj_results = _disj_results.create()
    _left_recursive_rules = _left_recursive_rules.create()
    _lr_states = _lr_states.create()

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

      rule.parse(this, 0, loc,
        {(result: Result[S, D, V]) =>
          match result
          | let success: Success[S, D, V] =>
            callback(success, success._values(data))
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
        Failure[S, D, V](rule, loc, ErrorMsg.empty_source()), Array[V])
    end

  be _parse_named_rule(
    depth: USize,
    rule: NamedRule[S, D, V] val,
    body: RuleNode[S, D, V] val,
    loc: Loc[S],
    cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this

    // look in memo for a top-level memoized result
    match _lookup(depth + 1, rule, loc)
    | let result: Result[S, D, V] =>
      cont(result)
      return
    end

    // if we can't be left-recursive, go ahead and parse
    if not _is_left_recursive(
      rule, per.Lists[NamedRule[S, D, V] val].empty())
    then
      body.parse(this, depth + 1, loc,
        {(result: Result[S, D, V]) =>
          match result
          | let success: Success[S, D, V] =>
            self._memoize(depth + 1, rule, loc, result, cont)
          else
            if rule.memoize_failures then
              self._memoize(depth + 1, rule, loc, result, cont)
            else
              cont(result)
            end
          end
        })
      return
    end

    // look in the LR records to see if we have a previous expansion
    match _prev_expansion(rule, loc, true)
    | (let result: Result[S, D, V], let first_lr: Bool) =>
      ifdef debug then
        if first_lr then
          _Dbg.out(depth + 1, rule.name + ": LR DETECTED")
        end
        let prev_exp = _current_expansion(rule, loc) - 1
        _Dbg.out(depth + 1, "fnd_exp " + rule.name + "@" + loc.string() + " <" +
          prev_exp.string() + "> " + result.string())
      end
      cont(result)
      return
    end

    // otherwise, memoize this rule as having failed for this expansion
    // and try parsing
    let failure = Failure[S, D, V](rule, loc)
    let topmost = _push_expansion(depth + 1, rule, loc, failure)

    ifdef debug then
      _Dbg.out(depth + 1, rule.name + "@" + loc.string() + " <" +
        _current_expansion(rule, loc).string() + ">")
    end
    _try_expansion(depth, rule, body, loc, topmost, cont)

  be _parse_disjunction_start(
    rule: Disj[S, D, V] val,
    disj: _DisjInstance,
    size: USize,
    depth: USize,
    loc: Loc[S],
    run: {()} iso,
    outer: _Continuation[S, D, V])
  =>
    _disj_results.update(disj, Array[(Result[S, D, V] | None)].init(None, size))
    run()

  be _parse_disjunction_child(
    disj: _DisjInstance,
    index: USize,
    rule: Disj[S, D, V] val,
    node: RuleNode[S, D, V] val,
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this
    node.parse(this, depth, loc,
      {(result: Result[S, D, V]) =>
        self._parse_disjunction_result(
          disj, index, rule, depth, loc, outer, result)
      })

  be _parse_disjunction_result(
    disj: _DisjInstance,
    index: USize,
    rule: Disj[S, D, V] val,
    depth: USize,
    loc: Loc[S],
    outer: _Continuation[S, D, V],
    result: Result[S, D, V])
  =>
    // no more results; we already found a solution, so bail
    if not _disj_results.contains(disj) then
      return
    end

    try
      let size = _disj_results(disj)?.size()
      _disj_results(disj)?(index)? = result

      var i: USize = 0
      for res in _disj_results(disj)?.values() do
        match res
        | None =>
          // no first result yet, give up
          return
        | let failure: Failure[S, D, V] =>
          // check for last failure, otherwise continue
          if i == (size - 1) then
            try _disj_results.remove(disj)? end
            outer(Failure[S, D, V](
              rule, loc, ErrorMsg.disjunction_failed(), failure))
          end
        | let success: Success[S, D, V] =>
          // we've found a first result, succeed
          try _disj_results.remove(disj)? end
          outer(Success[S, D, V](
            rule, success.start, success.next, [ success ]))
          return
        end
        i = i + 1
      end
    else
      try _disj_results.remove(disj)? end
      outer(Failure[S, D, V](rule, loc, ErrorMsg.disjunction_failed()))
    end

  fun ref _is_left_recursive(
    node: RuleNode[S, D, V] val,
    stack: per.List[NamedRule[S, D, V] val]): Bool
  =>
    match node
    | let named: NamedRule[S, D, V] val =>
      try
        return _left_recursive_rules(named)?
      end

      if stack.exists({(rn) => rn.name == named.name }) then
        return true
      end

      match named.body()
      | let body: RuleNode[S, D, V] val =>
        let is_lr = _is_left_recursive(body, stack.prepend(named))
        _left_recursive_rules(named) = is_lr
        return is_lr
      end
    | let conj: Conj[S, D, V] val =>
      try
        return _is_left_recursive(conj.children()(0)?, stack)
      end
    | let disj: Disj[S, D, V] val =>
      let children = disj.children()
      for i in col.Range(0, children.size()) do
        try
          let child = children(i)?
          if _is_left_recursive(child, stack) then
            return true
          end
        end
      end
    | let with_body: RuleNodeWithBody[S, D, V] val =>
      match with_body.body()
      | let body: RuleNode[S, D, V] val =>
        return _is_left_recursive(body, stack)
      end
    end
    false

  be _try_expansion(
    depth: USize,
    rule: NamedRule[S, D, V] val,
    body: RuleNode[S, D, V] val,
    loc: Loc[S],
    topmost: Bool,
    cont: _Continuation[S, D, V])
  =>
    let self: Parser[S, D, V] tag = this
    body.parse(this, depth + 2, loc,
      {(result: Result[S, D, V]) =>
        self._try_expansion_aux(result, depth, rule, body, loc, topmost, cont)
      })

  be _try_expansion_aux(
    result: Result[S, D, V],
    depth: USize,
    rule: NamedRule[S, D, V] val,
    body: RuleNode[S, D, V] val,
    loc: Loc[S],
    topmost: Bool,
    cont: _Continuation[S, D, V])
  =>
    if _lr_detected(rule, loc) then
      let cur_exp = _current_expansion(rule, loc)

      match result
      | let success: Success[S, D, V] =>
        let last_next = _last_next(rule, loc)
        if success.next > last_next then
          // try another expansion
          _remove_expansions_below(depth + 2, loc)
          _push_expansion(depth + 2, rule, loc, success)

          ifdef debug then
            _Dbg.out(depth + 1, rule.name + "@" + loc.string() + " <" +
              _current_expansion(rule, loc).string() + ">")
          end
          _try_expansion(
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

      // we're done; continue with the widest expansion
      let result' =
        match _prev_expansion(rule, loc)
        | (let r: Result[S, D, V], _) =>
          r
        else
          result
        end

      if topmost then
        // we're at the top level; memoize us and all rules below us,
        // then remove all LR records
        let to_memoize = _remove_expansions_below(0, loc)
        to_memoize.push((rule, loc, result'))
        _memoize_seq(
          depth + 1,
          consume to_memoize,
          result',
          cont)
      else
        // we're not at the top level; memoize in this expansions
        _update_expansion(depth + 1, rule, loc, result')
        cont(result')
      end
    elseif topmost then
      // no left-recursion was detected, memoize us globally
      let to_memoize = _remove_expansions_below(0, loc)
      to_memoize.push((rule, loc, result))
      _memoize_seq(
        depth + 1,
        consume to_memoize,
        result,
        cont)
    else
      // no left-recursion detected, but we are inside another,
      // memoize in this expansion
      _update_expansion(depth + 1, rule, loc, result)
      cont(result)
    end

  fun _lookup(depth: USize, rule: NamedRule[S, D, V] val, loc: Loc[S])
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
    depth: USize,
    rule: NamedRule[S, D, V] val,
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
    cont(result)

  be _memoize_seq(
    depth: USize,
    results: ReadSeq[(NamedRule[S, D, V] val, Loc[S], Result[S, D, V])] iso,
    result: Result[S, D, V],
    cont: _Continuation[S, D, V])
  =>
    for (rule, loc, res) in (consume results).values() do
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
    cont(result)

  fun ref _push_expansion(
    depth: USize,
    rule: NamedRule[S, D, V] val,
    loc: Loc[S],
    result: Result[S, D, V]): Bool
  =>
    let toplevel = _lr_states.size() == 0
    try
      let lr_state = _lr_states((rule, loc))?
      let cur_exp = lr_state.expansions.size()
      ifdef debug then
        _Dbg.out(depth, "mem_exp " + rule.name + "@" + loc.string() + " <" +
          cur_exp.string() + "> " + result.string())
      end
      lr_state.expansions.push(result)
    else
      let lr_state = _LRRuleState[S, D, V](depth, rule, loc)
      let cur_exp = lr_state.expansions.size()
      ifdef debug then
        _Dbg.out(depth, "mem_exp " + rule.name + "@" + loc.string() + " <" +
          cur_exp.string() + "> " + result.string())
      end
      lr_state.expansions.push(result)
      _lr_states((rule, loc)) = lr_state
    end
    toplevel

  fun ref _update_expansion(
    depth: USize,
    rule: NamedRule[S, D, V] val,
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    try
      let lr_state = _lr_states((rule, loc))?
      let prev_exp = lr_state.expansions.size() - 1
      ifdef debug then
        _Dbg.out(depth, "mem_upd " + rule.name + "@" + loc.string() + " <" +
          prev_exp.string() + "> " + result.string())
      end
      lr_state.expansions(prev_exp)? = result
    end

  fun _current_expansion(rule: NamedRule[S, D, V] val, loc: Loc[S]): USize =>
    try
      _lr_states((rule, loc))?.expansions.size()
    else
      0
    end

  fun ref _remove_expansions(rule: NamedRule[S, D, V] val, loc: Loc[S]) =>
    try
      _lr_states.remove((rule, loc))?
    end

  fun ref _remove_expansions_below(depth: USize, loc: Loc[S])
    : Array[(NamedRule[S, D, V] val, Loc[S], Result[S, D, V])] iso^
  =>
    let to_memoize =
      recover iso Array[(NamedRule[S, D, V] val, Loc[S], Result[S, D, V])] end
    let to_remove = Array[(NamedRule[S, D, V] val, Loc[S])]
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
    consume to_memoize

  fun ref _prev_expansion(
    rule: NamedRule[S, D, V] val,
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

  fun _lr_detected(rule: NamedRule[S, D, V] val, loc: Loc[S]): Bool =>
    try
      _lr_states((rule, loc))?.lr_detected
    else
      false
    end

  fun _last_next(rule: NamedRule[S, D, V] val, loc: Loc[S]): Loc[S] =>
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
