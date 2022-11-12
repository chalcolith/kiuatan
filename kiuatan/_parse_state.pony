use "collections"

class _LRRuleState[S, D: Any #share, V: Any #share]
  let depth: USize
  let rule: NamedRule[S, D, V]
  let loc: Loc[S]
  let expansions: Array[Result[S, D, V]] = expansions.create()
  var lr_detected: Bool = false

  new create(
    depth': USize,
    rule': NamedRule[S, D, V],
    loc': Loc[S])
  =>
    depth = depth'
    rule = rule'
    loc = loc'

class val _LRRuleLocHash[S, D: Any #share, V: Any #share]
  is HashFunction[(NamedRule[S, D, V], Loc[S])]
  new val create() =>
    None

  fun hash(x: (NamedRule[S, D, V], Loc[S])): USize =>
    x._1.name.hash() xor x._2.hash()

  fun eq(x: (NamedRule[S, D, V], Loc[S]), y: (NamedRule[S, D, V], Loc[S]))
    : Bool
  =>
    hash(x) == hash(y)

class iso _ParseState[S, D: Any #share, V: Any #share]
  let parser: Parser[S, D, V]
  let data: D
  let source: Source[S]
  let lr_states:
    HashMap[
      (NamedRule[S, D, V], Loc[S]),
      _LRRuleState[S, D, V],
      _LRRuleLocHash[S, D, V]
    ] = lr_states.create()

  new iso create(
    parser': Parser[S, D, V],
    data': D,
    source': Source[S])
  =>
    parser = parser'
    data = data'
    source = source'

  fun ref push_expansion(
    depth: USize,
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    result: Result[S, D, V]): Bool
  =>
    let toplevel = lr_states.size() == 0
    try
      let lr_state = lr_states((rule, loc))?
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
      lr_states((rule, loc)) = lr_state
    end
    toplevel

  fun ref update_expansion(
    depth: USize,
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    result: Result[S, D, V])
  =>
    try
      let lr_state = lr_states((rule, loc))?
      let prev_exp = lr_state.expansions.size() - 1
      ifdef debug then
        _Dbg.out(depth, "mem_upd " + rule.name + "@" + loc.string() + " <" +
          prev_exp.string() + "> " + result.string())
      end
      lr_state.expansions(prev_exp)? = result
    end

  fun current_expansion(rule: NamedRule[S, D, V], loc: Loc[S]): USize =>
    try
      lr_states((rule, loc))?.expansions.size()
    else
      0
    end

  fun ref remove_expansions(rule: NamedRule[S, D, V], loc: Loc[S]) =>
    try
      lr_states.remove((rule, loc))?
    end

  fun ref remove_expansions_below(depth: USize, loc: Loc[S])
    : Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] iso^
  =>
    let to_memoize: Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] iso
       = Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])]
    let to_remove = Array[(NamedRule[S, D, V], Loc[S])]
    for lr_state in lr_states.values() do
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
        lr_states.remove(key)?
      end
    end
    consume to_memoize

  fun ref prev_expansion(
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    detect_lr: Bool = false)
    : ((Result[S, D, V], Bool) | None)
  =>
    try
      let lr_state = lr_states((rule, loc))?
      let first_detected = not lr_state.lr_detected
      if detect_lr then
        lr_state.lr_detected = true
      end
      let prev_exp = lr_state.expansions.size() - 1
      let result = lr_state.expansions(prev_exp)?
      (result, first_detected)
    end

  fun lr_detected(rule: NamedRule[S, D, V], loc: Loc[S]): Bool =>
    try
      lr_states((rule, loc))?.lr_detected
    else
      false
    end

  fun last_next(rule: NamedRule[S, D, V], loc: Loc[S]): Loc[S] =>
    try
      let lr_state = lr_states((rule, loc))?
      let prev_exp = lr_state.expansions.size() - 1
      match lr_state.expansions(prev_exp)?
      | let success: Success[S, D, V] =>
        return success.next
      | let failure: Failure[S, D, V] =>
        return failure.start
      end
    end
    Loc[S](source)

  // fun ref cleanup(loc: Loc[S])
  //   : ReadSeq[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] val
  // =>
  //   let to_memoize: Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] trn =
  //     Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])]
  //   try
  //     let lr_state = _lr_states(loc)?
  //     for rule_results in lr_state.by_rule.values() do
  //       if rule_results.lr_detected then
  //         let prev_exp = rule_results.by_exp.size() - 1
  //         try
  //           to_memoize.push(
  //             (rule_results.rule, loc, rule_results.by_exp(prev_exp)?))
  //         end
  //       end
  //     end
  //     _lr_states.remove(loc)?
  //   end
  //   consume to_memoize
