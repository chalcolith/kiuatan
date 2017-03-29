use "collections"

type _SegToRuleMemo[TSrc,TRes] is MapIs[ParseSegment[TSrc] box, _RuleToExpMemo[TSrc,TRes]]
type _RuleToExpMemo[TSrc,TRes] is MapIs[ParseRule[TSrc,TRes] box, _ExpToLocMemo[TSrc,TRes]]
type _ExpToLocMemo[TSrc,TRes] is Map[USize, _LocToResultMemo[TSrc,TRes]]
type _LocToResultMemo[TSrc,TRes] is Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TRes] | None)]


class _Expansion[TSrc,TRes]
  let rule: ParseRule[TSrc,TRes] box
  let num: USize

  new create(rule': ParseRule[TSrc,TRes] box, num': USize) =>
    rule = rule'
    num = num'


class ParseState[TSrc,TRes]
  """
  Stores the memo and matcher stack for a particular match.
  """

  let _source: List[ReadSeq[TSrc]] box
  let _start: ParseLoc[TSrc] box

  let _memo_tables: _SegToRuleMemo[TSrc,TRes] = _memo_tables.create()

  new create(source': List[ReadSeq[TSrc]] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = source'
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

  fun ref call_with_memo(rule: ParseRule[TSrc,TRes] box, loc: ParseLoc[TSrc] box): (ParseResult[TSrc,TRes] | None) ? =>
    let exp = _Expansion[TSrc,TRes](rule, 0)
    
    match get_result(exp, loc)
    | let r: ParseResult[TSrc,TRes] => return r
    end

    let res = rule.parse(this, loc)
    memoize(exp, loc, res)
    res

  fun get_result(exp: _Expansion[TSrc,TRes], loc: ParseLoc[TSrc] box): (this->ParseResult[TSrc,TRes] | None) =>
    try
      let rule_memo = _memo_tables(loc.segment())
      let exp_memo = rule_memo(exp.rule)
      let loc_memo = exp_memo(exp.num)
      loc_memo(loc)
    else
      None
    end

  fun ref memoize(exp: _Expansion[TSrc,TRes], loc: ParseLoc[TSrc] box, res: (ParseResult[TSrc,TRes] | None)) ? =>
    let rule_memo = try
      _memo_tables(loc.segment())
    else
      _memo_tables.insert(loc.segment(), _RuleToExpMemo[TSrc,TRes]())
    end

    let exp_memo = try
      rule_memo(exp.rule)
    else
      rule_memo.insert(exp.rule, _ExpToLocMemo[TSrc,TRes]())
    end
    
    let loc_memo = try
      exp_memo(exp.num)
    else
      exp_memo.insert(exp.num, _LocToResultMemo[TSrc,TRes]())
    end

    loc_memo.insert(loc, res)

  fun ref forget(exp: _Expansion[TSrc,TRes], loc: ParseLoc[TSrc]) =>
    try
      let rule_memo = _memo_tables(loc.segment())
      let exp_memo = rule_memo(exp.rule)
      let loc_memo = exp_memo(exp.num)
      loc_memo.remove(loc)
    end
