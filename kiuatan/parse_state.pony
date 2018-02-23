
use "collections"
use "debug"

class ParseState[TSrc: Any #read, TVal = None]
  """
  Stores the state of a particular attempt to parse some input.
  """

  let _source: List[ReadSeq[TSrc] box] box

  let _memo_tables: _RuleToExpMemo[TSrc,TVal] = _memo_tables.create()

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
    _source = List[ReadSeq[TSrc] box].from([as ReadSeq[TSrc] box: seq])

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

  fun errors(loc: ParseLoc[TSrc] val): ParseError[TSrc,TVal] =>
    let rules = SetIs[RuleNode[TSrc,TVal] tag]
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
    loc: (ParseLoc[TSrc] val | None) = None)
    : (ParseResult[TSrc,TVal] val | None)
  =>
    """
    Attempts to parse the input against a particular grammar rule, starting
    at a particular location.  If `loc` is `None`, then the parse will begin
    at the beginning of the source.
    """
    try
      let start': ParseLoc[TSrc] val =
        match loc
        | let start'': ParseLoc[TSrc] val =>
          start''.clone()
        else
          // why can't we recover this?
          ParseLoc[TSrc](_source.head()?, 0).clone()
        end

      ifdef debug then
        Debug.out("parse(" + rule.name() + ", " + start'.string() + ")")
      end

      let result =
        match parse_with_memo(rule, start', CallState[TSrc,TVal])?
        | let res: ParseResult[TSrc,TVal] val =>
          res
        end

      ifdef debug then
        Debug.out("parse(" + rule.name() + ", " + start'.string() + ")" + _dbg_res(result))
      end

      result
    end

  fun ref parse_with_memo(
    rule: RuleNode[TSrc,TVal] box,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    match rule
    | let rule': ParseRule[TSrc,TVal] box =>
      try
        cs.call_stack.push(rule')

        ifdef debug then
          _dbg(cs, "parse_with_memo(" + rule'.name() + ", " + loc.string() + ")")
        end

        let base_expansion: _Expansion[TSrc,TVal] val =
          _Expansion[TSrc,TVal](rule', 0)

        let res =
          match _get_memoized_result(base_expansion, loc)
          | let result: ParseResult[TSrc,TVal] val =>
            result
          else
            if rule'.is_terminal() then
              _parse_non_recursive(rule', base_expansion, loc, cs)?
            else
              _parse_recursive(rule', base_expansion, loc, cs)?
            end
          end

        ifdef debug then
          _dbg(cs, "parse_with_memo(" + rule'.name() + ", " + loc.string()
            + ")" + _dbg_res(res))
        end
        return res
      then
        cs.call_stack.pop()?
      end
    else
      // do not memoize non-named nodes
      let res = rule.parse(this, loc, cs)?

      // but memoize error messages from RuleError
      match res
      | let msg: ParseErrorMessage =>
        _record_error(rule, msg, loc)
      end
      res
    end

  fun ref _parse_non_recursive(
    rule: ParseRule[TSrc,TVal] box,
    expansion: _Expansion[TSrc,TVal] val,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    let res = rule.parse(this, loc, cs)?
    _memoize(expansion, loc, res)?
    match res
    | let msg: ParseErrorMessage =>
      _record_error(rule, msg, loc)
    end
    res

  fun ref _parse_recursive(
    rule: ParseRule[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal] val,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    match _get_lr_record(rule, loc, cs)
    | let rec: _LRRecord[TSrc,TVal] =>
      _parse_existing_lr(rule, rec, loc, cs)
    else
      _parse_new_lr(rule, exp, loc, cs)?
    end

  fun ref _parse_existing_lr(
    rule: ParseRule[TSrc,TVal] box,
    rec: _LRRecord[TSrc,TVal],
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None)
  =>
    rec.lr_detected = true
    for lr in cs.rec_stack.values() do
      if lr.cur_expansion.rule is rule then break end
      rec.involved_rules.set(lr.cur_expansion.rule)
    end
    let res = _get_memoized_result(rec.cur_expansion, loc)
    ifdef debug then
      _dbg(cs, " _parse_existing_lr(" + rec.cur_expansion.string() + ", "
        + loc.string() + ")" + _dbg_res(res))
    end
    res

  fun ref _parse_new_lr(
    rule: ParseRule[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal] val,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    let rec = _LRRecord[TSrc,TVal](rule, loc)
    _memoize(rec.cur_expansion, loc, None)?
    _start_lr_record(rule, loc, cs, rec)
    cs.rec_stack.push(rec)

    var res: (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) = None
    while true do
      res = rule.parse(this, loc, cs)?
      match res
      | let r: ParseResult[TSrc,TVal] val
        if rec.lr_detected and (r.next > rec.cur_next_loc) =>
        rec.num_expansions = rec.num_expansions + 1
        rec.cur_expansion =
          recover _Expansion[TSrc,TVal](rule, rec.num_expansions) end
        rec.cur_next_loc = r.next
        rec.cur_result = r
        _memoize(rec.cur_expansion, loc, r)?
      else
        if rec.lr_detected then
          res = rec.cur_result
        end
        _forget_lr_record(rule, loc, cs)

        cs.rec_stack.pop()?
        var found = false
        for i in Range(cs.rec_stack.size(), 0, -1) do
          if cs.rec_stack(i - 1)?.involved_rules.contains(rule) then
            found = true
            break
          end
        end
        if not found then
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
    rule: RuleNode[TSrc,TVal] tag,
    msg: ParseErrorMessage val,
    loc: ParseLoc[TSrc] val)
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
        ParseError[TSrc,TVal](loc,
          SetIs[RuleNode[TSrc,TVal] tag].>set(rule),
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
        ParseError[TSrc,TVal](loc,
          SetIs[RuleNode[TSrc,TVal] tag].>set(rule),
          Set[ParseErrorMessage].>set(msg))
    end

  fun _get_memoized_result(
    exp: _Expansion[TSrc,TVal] val,
    loc: ParseLoc[TSrc] val)
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None)
  =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo(loc)?
    else
      None
    end

  fun ref _memoize(
    exp: _Expansion[TSrc,TVal] val,
    loc: ParseLoc[TSrc] val,
    res: (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None)) ?
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

  fun ref _forget(exp: _Expansion[TSrc,TVal] val, loc: ParseLoc[TSrc] val) =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo.remove(loc)?
    end

  fun ref forget_segment(segment: ParseSegment[TSrc]) =>
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        let to_delete = Array[ParseLoc[TSrc] val]
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
    rule: RuleNode[TSrc,TVal] tag,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (_LRRecord[TSrc,TVal] | None)
  =>
    try
      let loc_lr = cs.recursions(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun ref _start_lr_record(
    rule: RuleNode[TSrc,TVal] tag,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal],
    rec: _LRRecord[TSrc,TVal])
  =>
    try
      let loc_lr = try
        cs.recursions(rule)?
      else
        cs.recursions.insert(rule, _LocToLR[TSrc,TVal]())?
      end

      loc_lr.insert(loc, rec)?
    end

  fun ref _forget_lr_record(
    rule: RuleNode[TSrc,TVal] tag,
    loc: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
  =>
    try
      let loc_lr = cs.recursions(rule)?
      loc_lr.remove(loc)?
    end

  fun _dbg(cs: CallState[TSrc,TVal], s: String val) =>
    ifdef debug then
      let s' = String
      for i in Range(0, cs.call_stack.size()) do
        s'.append("  ")
      end
      s'.append(s)
      Debug.out(s')
    end

  fun _dbg_res(res:(ParseResult[TSrc,TVal] val | ParseErrorMessage val | None))
    : String
  =>
    match res
    | let r: ParseResult[TSrc,TVal] val =>
      "  => [" + r.start.string() + "," + r.next.string() + ")"
    | let m: ParseErrorMessage =>
      "  => '" + m + "'"
    else
      "  => None"
    end


type _RuleToExpMemo[TSrc: Any #read, TVal] is
  MapIs[RuleNode[TSrc,TVal] tag, _ExpToLocMemo[TSrc,TVal]]

type _ExpToLocMemo[TSrc: Any #read, TVal] is
  Map[USize, _LocToResultMemo[TSrc,TVal]]

type _LocToResultMemo[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] val,
    (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None)]

type _RuleToLocLR[TSrc: Any #read, TVal] is
  MapIs[RuleNode[TSrc,TVal] tag, _LocToLR[TSrc,TVal]]

type _LocToLR[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] val, _LRRecord[TSrc,TVal]]


class CallState[TSrc: Any #read, TVal = None]
  let call_stack: Array[ParseRule[TSrc,TVal] tag] = call_stack.create()
  let rec_stack: Array[_LRRecord[TSrc,TVal]] = rec_stack.create()
  let recursions: _RuleToLocLR[TSrc,TVal] = recursions.create()


class _Expansion[TSrc: Any #read, TVal]
  let rule: ParseRule[TSrc,TVal] box
  let num: USize

  new create(rule': ParseRule[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'

  fun string(): String =>
    rule.name() + ":" + num.string()


class _LRRecord[TSrc: Any #read, TVal]
  var lr_detected: Bool
  var num_expansions: USize
  var cur_expansion: _Expansion[TSrc,TVal] val
  var cur_next_loc: ParseLoc[TSrc] val
  var cur_result: (ParseResult[TSrc,TVal] val | None)
  var involved_rules: SetIs[ParseRule[TSrc,TVal] tag]

  new create(rule: ParseRule[TSrc,TVal] tag, loc: ParseLoc[TSrc] val) =>
    lr_detected = false
    num_expansions = 1
    cur_expansion = recover _Expansion[TSrc,TVal](rule, num_expansions) end
    cur_next_loc = loc
    cur_result = None
    involved_rules = SetIs[ParseRule[TSrc,TVal] tag]


class ParseError[TSrc: Any #read, TVal = None]
  var loc: ParseLoc[TSrc] val
  let rules: SetIs[RuleNode[TSrc,TVal] tag]
  let messages: Set[ParseErrorMessage val]

  new create(
    loc': ParseLoc[TSrc] val,
    rules': SetIs[RuleNode[TSrc,TVal] tag],
    msg': Set[ParseErrorMessage val])
  =>
    loc = loc'
    rules = rules'
    messages = msg'


type ParseErrorMessage is String
