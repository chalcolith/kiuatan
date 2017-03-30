use "collections"

type _SegToRuleMemo[TSrc,TVal] is MapIs[ParseSegment[TSrc] box, _RuleToExpMemo[TSrc,TVal]]
type _RuleToExpMemo[TSrc,TVal] is MapIs[ParseRule[TSrc,TVal] box, _ExpToLocMemo[TSrc,TVal]]
type _ExpToLocMemo[TSrc,TVal] is Map[USize, _LocToResultMemo[TSrc,TVal]]
type _LocToResultMemo[TSrc,TVal] is Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TVal] | None)]


class _Expansion[TSrc,TVal]
  let rule: ParseRule[TSrc,TVal] box
  let num: USize

  new create(rule': ParseRule[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'


class ParseState[TSrc,TVal]
  """
  Stores the memo and matcher stack for a particular match.
  """

  let _source: List[ReadSeq[TSrc]] box
  let _start: ParseLoc[TSrc] box

  let _memo_tables: _SegToRuleMemo[TSrc,TVal] = _memo_tables.create()

  new create(source': List[ReadSeq[TSrc]] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = source'
    _start = match start'
    | let loc: ParseLoc[TSrc] =>
      loc.clone()
    else
      ParseLoc[TSrc](_source.head(), 0)
    end
  
  new from_seq(seq: ReadSeq[TSrc] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = List[ReadSeq[TSrc]].from([as ReadSeq[TSrc]: seq])
    _start = match start'
    | let loc: ParseLoc[TSrc] =>
      loc.clone()
    else
      ParseLoc[TSrc](_source.head(), 0)
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

    let res = rule.parse(this, loc)
    memoize(exp, loc, res)
    res

  fun get_result(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc] box): (this->ParseResult[TSrc,TVal] | None) =>
    try
      let rule_memo = _memo_tables(loc.segment())
      let exp_memo = rule_memo(exp.rule)
      let loc_memo = exp_memo(exp.num)
      loc_memo(loc)
    else
      None
    end

  fun ref memoize(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc] box, res: (ParseResult[TSrc,TVal] | None)) ? =>
    let rule_memo = try
      _memo_tables(loc.segment())
    else
      _memo_tables.insert(loc.segment(), _RuleToExpMemo[TSrc,TVal]())
    end

    let exp_memo = try
      rule_memo(exp.rule)
    else
      rule_memo.insert(exp.rule, _ExpToLocMemo[TSrc,TVal]())
    end
    
    let loc_memo = try
      exp_memo(exp.num)
    else
      exp_memo.insert(exp.num, _LocToResultMemo[TSrc,TVal]())
    end

    loc_memo.insert(loc, res)

  fun ref forget(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc]) =>
    try
      let rule_memo = _memo_tables(loc.segment())
      let exp_memo = rule_memo(exp.rule)
      let loc_memo = exp_memo(exp.num)
      loc_memo.remove(loc)
    end
