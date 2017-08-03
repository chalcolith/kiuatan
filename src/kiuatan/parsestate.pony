use "collections"

class ParseState[TSrc,TVal]
  """
  Stores the state of a particular match.
  """

  let _source: List[ReadSeq[TSrc]] box
  let _start: ParseLoc[TSrc] box

  let _memo_tables: _RuleToExpMemo[TSrc,TVal] = _memo_tables.create()
  let _call_stack: List[_LRRecord[TSrc,TVal]] = _call_stack.create()
  let _cur_recursions: _RuleToLocLR[TSrc,TVal] = _cur_recursions.create()

  new create(source': List[ReadSeq[TSrc]] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = source'
    _start = match start'
    | let loc: ParseLoc[TSrc] =>
      loc.clone()
    else
      ParseLoc[TSrc](_source.head()?, 0)
    end
  
  new from_seq(seq: ReadSeq[TSrc] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = List[ReadSeq[TSrc]].from([as ReadSeq[TSrc]: seq])
    _start = match start'
    | let loc: ParseLoc[TSrc] =>
      loc.clone()
    else
      ParseLoc[TSrc](_source.head()?, 0)
    end

  fun box source(): List[ReadSeq[TSrc] box] box =>
    _source

  fun box start(): ParseLoc[TSrc] box =>
    _start

  fun ref call_with_memo(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    let exp = _Expansion[TSrc,TVal](rule, 0)
    
    match get_result(exp, loc)
    | let r: ParseResult[TSrc,TVal] => return r
    end

    if rule.can_be_recursive() then
      let res = rule.parse(this, loc)?
      memoize(exp, loc, res)?
      return res
    end

    match get_lr_record(rule, loc)
    | let rec: _LRRecord[TSrc,TVal] =>
      rec.lr_detected = true
      for lr in this._call_stack.rvalues() do
        if lr.cur_expansion.rule is rule then break end
        rec.involved_rules.set(lr.cur_expansion.rule)
      end
      get_result(rec.cur_expansion, loc)
    else
      let rec = _LRRecord[TSrc,TVal](rule, loc)
      memoize(rec.cur_expansion, loc, None)?
      start_lr_record(rule, loc, rec)
      _call_stack.unshift(rec)

      var res: (ParseResult[TSrc,TVal] | None) = None
      while true do
        res = rule.parse(this, loc)?
        match res
        | (let r: ParseResult[TSrc,TVal]) if rec.lr_detected and (r.next > rec.cur_next_loc) =>
          rec.num_expansions = rec.num_expansions + 1
          rec.cur_expansion = _Expansion[TSrc,TVal](rule, rec.num_expansions)
          rec.cur_next_loc = r.next
          rec.cur_result = r
          memoize(rec.cur_expansion, loc, r)?
        else
          if rec.lr_detected then
            res = rec.cur_result
          end
          forget_lr_record(rule, loc)
          _call_stack.shift()?
          if not _call_stack.exists({
              (r: _LRRecord[TSrc,TVal] box): Bool => 
                r.involved_rules.contains(rule)
          }) then
            memoize(exp, loc, res)?
          end
          break
        end
      end
      res
    end

  fun get_result(exp: _Expansion[TSrc,TVal] box, loc: ParseLoc[TSrc] box): (this->ParseResult[TSrc,TVal] | None) =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo(loc)?
    else
      None
    end

  fun ref memoize(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc] box, res: (ParseResult[TSrc,TVal] | None)) ? =>
    let exp_memo = try
      _memo_tables(exp.rule)?
    else
      _memo_tables.insert(exp.rule, _ExpToLocMemo[TSrc,TVal]())?
    end
    
    let loc_memo = try
      exp_memo(exp.num)?
    else
      exp_memo.insert(exp.num, _LocToResultMemo[TSrc,TVal]())?
    end

    loc_memo.insert(loc, res)?

  fun ref forget(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc]) =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo.remove(loc)?
    end

  fun ref get_lr_record(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box): (_LRRecord[TSrc,TVal] | None) =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun ref start_lr_record(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box, rec: _LRRecord[TSrc,TVal]) =>
    try
      let loc_lr = try
        _cur_recursions(rule)?
      else
        _cur_recursions.insert(rule, _LocToLR[TSrc,TVal]())?
      end

      loc_lr.insert(loc, rec)?
    end

  fun ref forget_lr_record(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box) =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr.remove(loc)?
    end


type _RuleToExpMemo[TSrc,TVal] is MapIs[ParseRule[TSrc,TVal] box, _ExpToLocMemo[TSrc,TVal]]
type _ExpToLocMemo[TSrc,TVal] is Map[USize, _LocToResultMemo[TSrc,TVal]]
type _LocToResultMemo[TSrc,TVal] is Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TVal] | None)]

type _RuleToLocLR[TSrc,TVal] is MapIs[ParseRule[TSrc,TVal] box, _LocToLR[TSrc,TVal]]
type _LocToLR[TSrc,TVal] is Map[ParseLoc[TSrc] box, _LRRecord[TSrc,TVal]]


class _Expansion[TSrc,TVal]
  let rule: ParseRule[TSrc,TVal] box
  let num: USize

  new create(rule': ParseRule[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'


class _LRRecord[TSrc,TVal]
  var lr_detected: Bool
  var num_expansions: USize
  var cur_expansion: _Expansion[TSrc,TVal]
  var cur_next_loc: ParseLoc[TSrc] box
  var cur_result: (ParseResult[TSrc,TVal] | None)
  var involved_rules: SetIs[ParseRule[TSrc,TVal] tag]

  new create(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box) =>
    lr_detected = false
    num_expansions = 1
    cur_expansion = _Expansion[TSrc,TVal](rule, num_expansions)
    cur_next_loc = loc
    cur_result = None
    involved_rules = SetIs[ParseRule[TSrc,TVal] tag]
