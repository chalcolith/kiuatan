
use "collections"
use "debug"

class ParseState[TSrc: Any #read, TVal = None]
  """
  Stores the state of a particular attempt to parse some input.
  """

  let _source: List[ReadSeq[TSrc] box] box

  let _memo_tables: _RuleToExpMemo[TSrc,TVal] = _memo_tables.create()
  let _call_stack: List[_LRRecord[TSrc,TVal]] = _call_stack.create()
  let _cur_recursions: _RuleToLocLR[TSrc,TVal] = _cur_recursions.create()

  var _last_error: (ParseError[TSrc,TVal] | None) = None
  var _farthest_error: (ParseError[TSrc,TVal] | None) = None

  new create(source': List[ReadSeq[TSrc] box] box) =>
    """
    Creates a new parse state using `source'` as the linked list of input
    sequences.
    """
    _source = source'

  new from_single_seq(seq: ReadSeq[TSrc] box) =>
    """
    Creates a new parse state from a single sequence of inputs.
    """
    _source = List[ReadSeq[TSrc]].from([as ReadSeq[TSrc]: seq])

  fun source(): List[ReadSeq[TSrc] box] box =>
    """
    Returns the input source used by this parse state.
    """
    _source

  fun start(): ParseLoc[TSrc] ? =>
    ParseLoc[TSrc](_source.head()?, 0)

  fun last_error(): (this->ParseError[TSrc,TVal] | None) =>
    _last_error

  fun farthest_error(): (this->ParseError[TSrc,TVal] | None) =>
    _farthest_error

  fun errors(loc: ParseLoc[TSrc] box): ParseError[TSrc,TVal] =>
    let rules = SetIs[RuleNode[TSrc,TVal] box]
    let messages = Set[ParseErrorMessage]
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        try
          match loc_memo(loc)?
          | let msg: ParseErrorMessage =>
            messages.set(msg)
          | None =>
            rules.set(rule)
          end
        end
      end
    end
    ParseError[TSrc,TVal](loc, rules, messages)

  fun ref parse(
    rule: ParseRule[TSrc,TVal] box,
    loc: (ParseLoc[TSrc] box | None) = None)
    : (ParseResult[TSrc,TVal] | None)
  =>
    """
    Attempts to parse the input against a particular grammar rule, starting
    at a particular location.  If `loc` is `None`, then the parse will begin
    at the beginning of the source.
    """
    try
      let start' =
        match loc
        | let start'': ParseLoc[TSrc] box =>
          start''
        else
          ParseLoc[TSrc](_source.head()?, 0)
        end

      match parse_with_memo(rule, start')?
      | let res: ParseResult[TSrc,TVal] =>
        res
      end
    end

  fun ref parse_with_memo(
    rule: RuleNode[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let base_expansion = _Expansion[TSrc,TVal](rule, 0)

    match rule
    | let _: ParseRule[TSrc,TVal] box =>
      match _get_memoized_result(base_expansion, loc)
      | let result: ParseResult[TSrc,TVal] =>
        result
      else
        if rule.is_terminal() then
          _parse_non_recursive(rule, base_expansion, loc)?
        else
          _parse_recursive(rule, base_expansion, loc)?
        end
      end
    else
      // do not memoize non-named nodes' successes, but record their errors
      let res = rule.parse(this, loc)?
      match res
      | let msg: ParseErrorMessage =>
        _record_error(rule, msg, loc)
      end
      res
    end

  fun ref _parse_non_recursive(
    rule: RuleNode[TSrc,TVal] box,
    expansion: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let res = rule.parse(this, loc)?
    _memoize(expansion, loc, res)?
    match res
    | let msg: ParseErrorMessage =>
      _record_error(rule, msg, loc)
    end
    res

  fun ref _parse_recursive(
    rule: RuleNode[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    match _get_lr_record(rule, loc)
    | let rec: _LRRecord[TSrc,TVal] =>
      _parse_existing_lr(rule, rec, loc)
    else
      _parse_new_lr(rule, exp, loc)?
    end

  fun ref _parse_existing_lr(
    rule: RuleNode[TSrc,TVal] box,
    rec: _LRRecord[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None)
  =>
    rec.lr_detected = true
    for lr in _call_stack.values() do
      if lr.cur_expansion.rule is rule then break end
      rec.involved_rules.set(lr.cur_expansion.rule)
    end
    _get_memoized_result(rec.cur_expansion, loc)

  fun ref _parse_new_lr(
    rule: RuleNode[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let rec = _LRRecord[TSrc,TVal](rule, loc)
    _memoize(rec.cur_expansion, loc, None)?
    _start_lr_record(rule, loc, rec)
    _call_stack.unshift(rec)

    var res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None) = None
    while true do
      res = rule.parse(this, loc)?
      match res
      | let r: ParseResult[TSrc,TVal]
        if rec.lr_detected and (r.next > rec.cur_next_loc) =>
        rec.num_expansions = rec.num_expansions + 1
        rec.cur_expansion = _Expansion[TSrc,TVal](rule, rec.num_expansions)
        rec.cur_next_loc = r.next
        rec.cur_result = r
        _memoize(rec.cur_expansion, loc, r)?
      else
        if rec.lr_detected then
          res = rec.cur_result
        end
        _forget_lr_record(rule, loc)
        _call_stack.shift()?
        if not _call_stack.exists(
          {(r: _LRRecord[TSrc,TVal] box): Bool =>
            r.involved_rules.contains(rule) }) then
          _memoize(exp, loc, res)?
        end

        match res
        | let msg: ParseErrorMessage =>
          _record_error(rule, msg, loc)
        end
        break
      end
    end
    res

  fun ref _record_error(
    rule: RuleNode[TSrc,TVal] box,
    msg: ParseErrorMessage,
    loc: ParseLoc[TSrc] box)
  =>
    match _last_error
    | let err: ParseError[TSrc,TVal] =>
      err.loc = loc
      err.rules.clear()
      err.rules.set(rule)
      err.messages.clear()
      err.messages.set(msg)
    else
      _last_error =
        ParseError[TSrc,TVal](
          loc,
          SetIs[RuleNode[TSrc,TVal] box].>set(rule),
          Set[ParseErrorMessage].>set(msg))
    end

    match _farthest_error
    | let err: ParseError[TSrc,TVal] =>
      if loc >= err.loc then
        if not (loc == err.loc) then
          err.loc = loc
          err.rules.clear()
          err.messages.clear()
        end
        err.rules.set(rule)
        err.messages.set(msg)
      end
    else
      _farthest_error =
        ParseError[TSrc,TVal](
          loc,
          SetIs[RuleNode[TSrc,TVal] box].>set(rule),
          Set[ParseErrorMessage].>set(msg))
    end

  fun _get_memoized_result(
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

  fun ref forget_segment(segment: ParseSegment[TSrc]) =>
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        let to_delete = Array[ParseLoc[TSrc] box]
        for (loc, _) in loc_memo.pairs() do
          if loc.segment() is segment then
            to_delete.push(loc)
          end
        end
        for loc in to_delete.values() do
          try loc_memo.remove(loc)? end
        end
      end
    end

  fun ref _get_lr_record(
    rule: RuleNode[TSrc,TVal] box,
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
    rule: RuleNode[TSrc,TVal] box,
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
    rule: RuleNode[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
  =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr.remove(loc)?
    end

  fun _dbg(s: String val) =>
    ifdef debug then
      let s' = String
      for i in Range(0, _call_stack.size()) do
        s'.append("  ")
      end
      s'.append(s)
      Debug.out(s)
    end

  fun _dbg_res(res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None)) =>
    match res
    | let r: ParseResult[TSrc,TVal] =>
      Debug.out("  => [" + r.start.string() + "," + r.next.string() + ")")
    | let m: ParseErrorMessage =>
      Debug.out("  => " + m)
    else
      Debug.out("  => None")
    end


class ParseError[TSrc: Any #read, TVal = None]
  var loc: ParseLoc[TSrc] box
  let rules: SetIs[RuleNode[TSrc,TVal] box]
  let messages: Set[ParseErrorMessage]

  new create(
    loc': ParseLoc[TSrc] box,
    rules': SetIs[RuleNode[TSrc,TVal] box],
    msg': Set[ParseErrorMessage])
  =>
    loc = loc'
    rules = rules'
    messages = msg'


type ParseErrorMessage is String

type _RuleToExpMemo[TSrc: Any #read, TVal] is
  MapIs[RuleNode[TSrc,TVal] box, _ExpToLocMemo[TSrc,TVal]]

type _ExpToLocMemo[TSrc: Any #read, TVal] is
  Map[USize, _LocToResultMemo[TSrc,TVal]]

type _LocToResultMemo[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TVal] | ParseErrorMessage | None)]

type _RuleToLocLR[TSrc: Any #read, TVal] is
  MapIs[RuleNode[TSrc,TVal] box, _LocToLR[TSrc,TVal]]

type _LocToLR[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, _LRRecord[TSrc,TVal]]


class _Expansion[TSrc: Any #read, TVal]
  let rule: RuleNode[TSrc,TVal] box
  let num: USize

  new create(rule': RuleNode[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'


class _LRRecord[TSrc: Any #read, TVal]
  var lr_detected: Bool
  var num_expansions: USize
  var cur_expansion: _Expansion[TSrc,TVal]
  var cur_next_loc: ParseLoc[TSrc] box
  var cur_result: (ParseResult[TSrc,TVal] | None)
  var involved_rules: SetIs[RuleNode[TSrc,TVal] box]

  new create(rule: RuleNode[TSrc,TVal] box, loc: ParseLoc[TSrc] box) =>
    lr_detected = false
    num_expansions = 1
    cur_expansion = _Expansion[TSrc,TVal](rule, num_expansions)
    cur_next_loc = loc
    cur_result = None
    involved_rules = SetIs[RuleNode[TSrc,TVal] box]
