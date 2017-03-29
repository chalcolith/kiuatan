type RuleResult[TSrc,TVal] is (ParseResult[TSrc,TVal] | None)
type RuleAction[TSrc,TVal] is (ParseAction[TSrc,TVal] val | None)

trait ParseRule[TSrc,TVal]
  """
  A rule in a grammar.
  """

  fun is_recursive(): Bool =>
    false

  fun box parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box): RuleResult[TSrc,TVal] ?


class ParseAny[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _action: RuleAction[TSrc,TVal]

  new create(action: RuleAction[TSrc,TVal] = None) =>
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): RuleResult[TSrc,TVal] ? =>
    let cur = start.clone()
    if cur.has_next() then 
      cur.next()
    else
      return None 
    end

    match _action
    | None => 
      ParseResult[TSrc,TVal].from_value(memo, start, cur, Array[ParseResult[TSrc,TVal]](), None)
    | let action: ParseAction[TSrc,TVal] val =>
      ParseResult[TSrc,TVal].from_action(memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end


class ParseLiteral[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _expected: ReadSeq[TSrc] box
  let _action: RuleAction[TSrc,TVal]

  new create(expected: ReadSeq[TSrc] box,
             action: RuleAction[TSrc,TVal] = None) =>
    _expected = expected
    _action = action

  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): RuleResult[TSrc,TVal] ? =>
    let cur = start.clone()
    for expected in _expected.values() do
      if not cur.has_next() then return None end
      let actual = cur.next()
      if expected != actual then return None end
    end

    match _action
    | None => 
      ParseResult[TSrc,TVal].from_value(memo, start, cur, Array[ParseResult[TSrc,TVal]](), None)
    | let action: ParseAction[TSrc,TVal] val =>
      ParseResult[TSrc,TVal].from_action(memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end


class ParseSequence[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: RuleAction[TSrc,TVal]

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: RuleAction[TSrc,TVal] = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): RuleResult[TSrc,TVal] ? =>
    let results = Array[ParseResult[TSrc,TVal]](_children.size())
    var cur = start
    for rule in _children.values() do
      match memo.call_with_memo(rule, cur)
      | let r: ParseResult[TSrc,TVal] =>
        results.push(r)
        cur = r.next
      else
        return None
      end
    end
    ParseResult[TSrc,TVal].from_action(memo, start, cur, results, _action)


class ParseChoice[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: RuleAction[TSrc,TVal]

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: RuleAction[TSrc,TVal] = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): RuleResult[TSrc,TVal] ? =>
    for rule in _children.values() do
      var cur = start.clone()
      match memo.call_with_memo(rule, cur)
      | let r: ParseResult[TSrc,TVal] =>
        return ParseResult[TSrc,TVal].from_action(memo, start, r.next, [r], _action)
      end
    end
    None
