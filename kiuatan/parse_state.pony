
use "collections"
use "debug"

class ParseState[TSrc: Any #read, TVal = None]
  """
  Stores the state of a particular parse.
  """

  let _source: List[ReadSeq[TSrc] box] box
  let _start: ParseLoc[TSrc] box

  let _memo_tables: _RuleToExpMemo[TSrc,TVal] = _memo_tables.create()
  let _call_stack: List[_LRRecord[TSrc,TVal]] = _call_stack.create()
  let _cur_recursions: _RuleToLocLR[TSrc,TVal] = _cur_recursions.create()

  new create(
    source': List[ReadSeq[TSrc] box] box,
    start': (ParseLoc[TSrc] | None) = None) ?
  =>
    _source = source'
    _start =
      match start'
      | let loc: ParseLoc[TSrc] =>
        loc.clone()
      else
        ParseLoc[TSrc](_source.head()?, 0)
      end

  new from_single_seq(
    seq: ReadSeq[TSrc] box,
    start': (ParseLoc[TSrc] | None) = None) ?
  =>
    _source = List[ReadSeq[TSrc]].from([as ReadSeq[TSrc]: seq])
    _start = match start'
    | let loc: ParseLoc[TSrc] =>
      loc.clone()
    else
      ParseLoc[TSrc](_source.head()?, 0)
    end

  fun source(): List[ReadSeq[TSrc] box] box =>
    _source

  fun start(): ParseLoc[TSrc] box =>
    _start


  fun ref parse(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    match memoparse(rule, loc)?
    | let res: ParseResult[TSrc,TVal] =>
      res
    end


  fun ref memoparse(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let exp = _Expansion[TSrc,TVal](rule, 0)

    var depth = _call_stack.size()
    let indent = _get_indent(depth)
    Debug.out(indent + "parse: looking for " + exp.rule.description()
      + ":" + exp.num.string() + " (" + depth.string() + " deep) at "
      + loc.string())

    match _get_result(exp, loc)
    | let r: ParseResult[TSrc,TVal] =>
      Debug.out(indent + "got memoized result @" + r.start.string() + "-"
        + r.next.string())
      return r
    end

    if not rule.can_be_recursive() then
      let res = rule.parse(this, loc)?
      _memoize(exp, loc, res)?
      match res
      | let r: ParseResult[TSrc,TVal] =>
        Debug.out(indent + "memoizing non-recursive result for "
          + exp.rule.description() + " @" + r.start.string() + "-"
          + r.next.string())
      else
        Debug.out(indent + "memoizing non-recursive failure for "
          + exp.rule.description() + "; return None")
      end
      return res
    end

    match _get_lr_record(rule, loc)
    | let rec: _LRRecord[TSrc,TVal] =>
      Debug.out(indent + "got LR record")

      rec.lr_detected = true
      for lr in this._call_stack.values() do
        if lr.cur_expansion.rule is rule then break end
        rec.involved_rules.set(lr.cur_expansion.rule)
      end
      let res = _get_result(rec.cur_expansion, loc)
      match res
      | let res': ParseResult[TSrc,TVal] =>
        Debug.out(indent + "returning @" + res'.start.string() + "-"
          + res'.next.string() + " for " + rec.cur_expansion.rule.description()
          + ":" + rec.cur_expansion.num.string())
      else
        Debug.out(indent + "returning None for "
          + rec.cur_expansion.rule.description()
          + ":" + rec.cur_expansion.num.string())
      end
      return res
    else
      let rec = _LRRecord[TSrc,TVal](rule, loc)
      Debug.out(indent + "start LR record; memoize failure for "
        + rec.cur_expansion.rule.description() + ":"
        + rec.cur_expansion.num.string())

      _memoize(rec.cur_expansion, loc, None)?
      _start_lr_record(rule, loc, rec)
      _call_stack.unshift(rec)

      var res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None) = None
      while true do
        Debug.out(indent + "LR search for "
          + rec.cur_expansion.rule.description() + ":"
          + rec.cur_expansion.num.string()
          + " @" + loc.string())
        res = rule.parse(this, loc)?
        match res
        | (let r: ParseResult[TSrc,TVal])
          if rec.lr_detected and (r.next > rec.cur_next_loc) =>
          rec.num_expansions = rec.num_expansions + 1
          rec.cur_expansion = _Expansion[TSrc,TVal](rule, rec.num_expansions)
          rec.cur_next_loc = r.next
          rec.cur_result = r
          Debug.out(indent + "memoize intermediate result @" + r.start.string()
            + "-" + r.next.string() + " for " + rec.cur_expansion.rule.description()
            + ":" + rec.cur_expansion.num.string())
          _memoize(rec.cur_expansion, loc, r)?
        else
          if rec.lr_detected then
            res = rec.cur_result
          end
          _forget_lr_record(rule, loc)
          _call_stack.shift()?
          if not _call_stack.exists({ (r: _LRRecord[TSrc,TVal] box): Bool =>
              r.involved_rules.contains(rule) }) then
            Debug.out(indent + "not involved; memoizing @" + loc.string()
              + " for " + rec.cur_expansion.rule.description()
              + ":" + rec.cur_expansion.num.string())
            _memoize(exp, loc, res)?
          end

          match res
          | let r': ParseResult[TSrc,TVal] =>
            Debug.out(indent + "end LR search; found result @"
              + r'.start.string() + "-" + r'.next.string() + " for "
              + rec.cur_expansion.rule.description() + ":"
              + rec.cur_expansion.num.string())
          else
            Debug.out(indent + "end LR search; found None for "
              + rec.cur_expansion.rule.description()
              + ":" + rec.cur_expansion.num.string())
          end
          break
        end
      end
      return res
    end

  fun _get_indent(n: USize): String =>
    var indent: String trn = recover String end
    var i = n
    while i > 0 do
      indent.append("  ")
      i = i - 1
    end
    indent

  fun _get_result(
    exp: _Expansion[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (this->ParseResult[TSrc,TVal] | ParseErrorMessage | None)
  =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo(loc)?
    else
      None
    end

  fun ref _memoize(
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box,
    res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None)) ?
  =>
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

  fun ref _forget(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc]) =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo.remove(loc)?
    end

  fun ref _get_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (_LRRecord[TSrc,TVal] | None)
  =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun ref _start_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box,
    rec: _LRRecord[TSrc,TVal])
  =>
    try
      let loc_lr = try
        _cur_recursions(rule)?
      else
        _cur_recursions.insert(rule, _LocToLR[TSrc,TVal]())?
      end

      loc_lr.insert(loc, rec)?
    end

  fun ref _forget_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
  =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr.remove(loc)?
    end

  fun last_error(): (ParseError[TSrc,TVal] | None) =>
    var farthest = _start
    let rules = SetIs[ParseRule[TSrc,TVal] box]
    let messages = Array[ParseErrorMessage]
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        for (loc, res) in loc_memo.pairs() do
          match res
          | let msg: ParseErrorMessage =>
            if not (loc < farthest) then
              if not (loc == farthest) then
                farthest = loc
                rules.clear()
                messages.clear()
              end
              rules.set(rule)
              messages.push(msg)
            end
          end
        end
      end
    end
    if rules.size() > 0 then
      ParseError[TSrc,TVal](farthest, rules, messages)
    end


class ParseError[TSrc: Any #read, TVal = None]
  let loc: ParseLoc[TSrc] box
  let rules: SetIs[ParseRule[TSrc,TVal] box] box
  let messages: Array[ParseErrorMessage] box

  new create(
    loc': ParseLoc[TSrc] box,
    rules': SetIs[ParseRule[TSrc,TVal] box] box,
    msg': Array[ParseErrorMessage] box)
  =>
    loc = loc'
    rules = rules'
    messages = msg'


type ParseErrorMessage is String

type _RuleToExpMemo[TSrc: Any #read, TVal] is
  MapIs[ParseRule[TSrc,TVal] box, _ExpToLocMemo[TSrc,TVal]]

type _ExpToLocMemo[TSrc: Any #read, TVal] is
  Map[USize, _LocToResultMemo[TSrc,TVal]]

type _LocToResultMemo[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TVal] | ParseErrorMessage | None)]

type _RuleToLocLR[TSrc: Any #read, TVal] is
  MapIs[ParseRule[TSrc,TVal] box, _LocToLR[TSrc,TVal]]

type _LocToLR[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, _LRRecord[TSrc,TVal]]


class _Expansion[TSrc: Any #read, TVal]
  let rule: ParseRule[TSrc,TVal] box
  let num: USize

  new create(rule': ParseRule[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'


class _LRRecord[TSrc: Any #read, TVal]
  var lr_detected: Bool
  var num_expansions: USize
  var cur_expansion: _Expansion[TSrc,TVal]
  var cur_next_loc: ParseLoc[TSrc] box
  var cur_result: (ParseResult[TSrc,TVal] | None)
  var involved_rules: SetIs[ParseRule[TSrc,TVal] box]

  new create(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box) =>
    lr_detected = false
    num_expansions = 1
    cur_expansion = _Expansion[TSrc,TVal](rule, num_expansions)
    cur_next_loc = loc
    cur_result = None
    involved_rules = SetIs[ParseRule[TSrc,TVal] box]
