class iso _ParseState[S, D: Any #share, V: Any #share]
  let parser: Parser[S, D, V]
  let data: D
  let source: Source[S]
  let _lr_stack: Array[_LRState[S, D, V]]

  new iso create(
    parser': Parser[S, D, V],
    data': D,
    source': Source[S])
  =>
    parser = parser'
    data = data'
    source = source'
    _lr_stack = Array[_LRState[S, D, V]]

  fun ref push_state(
    rule: NamedRule[S, D, V],
    loc: Loc[S],
    result: Result[S, D, V])
    : USize
  =>
    let index = _lr_stack.size()
    _lr_stack.push(_LRState[S, D, V](rule, loc, result))
    index

  fun ref existing_lr_state(
    rule: NamedRule[S, D, V],
    depth: USize,
    loc: Loc[S])
    : (Result[S, D, V] | None)
  =>
    for lr_state in _lr_stack.values() do
      if (lr_state.loc == loc) and (lr_state.rule is rule) then
        // mark this record as having found an LR
        let detected = lr_state.lr_detected
        lr_state.lr_detected = true

        // return the value of our last expansion
        let result =
          try
            lr_state.expansions(lr_state.expansions.size() - 1)?
          else
            Failure[S, D, V](rule, lr_state.loc, data,
              ErrorMsg._lr_not_memoized())
          end
        ifdef debug then
          if not detected then
            _Dbg.out(depth + 2, rule.name + ": LR DETECTED")
          end
          _Dbg.out(depth + 2, "found " + rule.name + "::" +
            lr_state.expansions.size().string())
        end
        return result
      end
    end

  fun lr_detected(lr_index: USize): Bool =>
    try
      _lr_stack(lr_index)?.lr_detected
    else
      false
    end

  fun next(lr_index: USize): Loc[S] =>
    try
      let exps = _lr_stack(lr_index)?.expansions
      match exps(exps.size() - 1)?
      | let success: Success[S, D, V] =>
        return success.next
      | let failure: Success[S, D, V] =>
        return failure.start
      end
    end
    Loc[S](source)

  fun cur_exp(lr_index: USize): USize =>
    try
      _lr_stack(lr_index)?.expansions.size()
    else
      0
    end

  fun ref push_result(lr_index: USize, result: Result[S, D, V]) =>
    try
      _lr_stack(lr_index)?.expansions.push(result)
    end

  fun ref cleanup(depth: USize)
    : ReadSeq[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] val
  =>
    let to_memoize: Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])] trn =
      Array[(NamedRule[S, D, V], Loc[S], Result[S, D, V])]
    for lr_state in _lr_stack.values() do
      try
        let res = lr_state.expansions(lr_state.expansions.size() - 1)?
        ifdef debug then
          _Dbg.out(depth + 2, "memoizing " + lr_state.rule.name + "::0 " +
            res.string())
        end
        to_memoize.push((lr_state.rule, lr_state.loc, res))
      end
    end
    _lr_stack.clear()
    consume to_memoize

class _LRState[S, D: Any #share, V: Any #share]
  let rule: NamedRule[S, D, V]
  let loc: Loc[S]
  var next: Loc[S]
  let expansions: Array[Result[S, D, V]]
  var lr_detected: Bool

  new create(
    rule': NamedRule[S, D, V],
    loc': Loc[S],
    first_expansion': Result[S, D, V])
  =>
    rule = rule'
    loc = loc'
    next = loc'
    expansions = [ first_expansion' ]
    lr_detected = false
