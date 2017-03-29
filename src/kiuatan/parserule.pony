type RuleResult[TSrc,TRes] is (ParseResult[TSrc,TRes] | None)
type RuleAction[TSrc,TRes] is (ParseAction[TSrc,TRes] val | None)

trait ParseRule[TSrc,TRes]
  """
  A rule in a grammar.
  """

  fun is_recursive(): Bool =>
    false

  fun box parse(memo: ParseState[TSrc,TRes] ref, start: ParseLoc[TSrc] box): RuleResult[TSrc,TRes] ?


class ParseAny[TSrc: Equatable[TSrc] #read, TRes] is ParseRule[TSrc,TRes]
  let _action: RuleAction[TSrc,TRes]

  new create(action: RuleAction[TSrc,TRes] = None) =>
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TRes], start: ParseLoc[TSrc] box): RuleResult[TSrc,TRes] ? =>
    let cur = start.clone()
    if cur.has_next() then 
      cur.next()
    else
      return None 
    end

    match _action
    | None => 
      ParseResult[TSrc,TRes].from_value(memo, start, cur, Array[ParseResult[TSrc,TRes]](), None)
    | let action: ParseAction[TSrc,TRes] val =>
      ParseResult[TSrc,TRes].from_action(memo, start, cur, Array[ParseResult[TSrc,TRes]](), action)
    end


class ParseLiteral[TSrc: Equatable[TSrc] #read, TRes] is ParseRule[TSrc,TRes]
  let _expected: ReadSeq[TSrc] box
  let _action: RuleAction[TSrc,TRes]

  new create(expected: ReadSeq[TSrc] box,
             action: RuleAction[TSrc,TRes] = None) =>
    _expected = expected
    _action = action

  fun box parse(memo: ParseState[TSrc,TRes], start: ParseLoc[TSrc] box): RuleResult[TSrc,TRes] ? =>
    let cur = start.clone()
    for expected in _expected.values() do
      if not cur.has_next() then return None end
      let actual = cur.next()
      if expected != actual then return None end
    end

    match _action
    | None => 
      ParseResult[TSrc,TRes].from_value(memo, start, cur, Array[ParseResult[TSrc,TRes]](), None)
    | let action: ParseAction[TSrc,TRes] val =>
      ParseResult[TSrc,TRes].from_action(memo, start, cur, Array[ParseResult[TSrc,TRes]](), action)
    end


class ParseSequence[TSrc: Equatable[TSrc] #read, TRes] is ParseRule[TSrc,TRes]
  let _children: ReadSeq[ParseRule[TSrc,TRes] box]
  let _action: RuleAction[TSrc,TRes]

  new create(children: ReadSeq[ParseRule[TSrc,TRes] box] box,
             action: RuleAction[TSrc,TRes] = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TRes], start: ParseLoc[TSrc] box): RuleResult[TSrc,TRes] ? =>
    let results = Array[ParseResult[TSrc,TRes]](_children.size())
    var cur = start
    for rule in _children.values() do
      match memo.call_with_memo(rule, cur)
      | let r: ParseResult[TSrc,TRes] =>
        results.push(r)
        cur = r.next
      else
        return None
      end
    end
    ParseResult[TSrc,TRes].from_action(memo, start, cur, results, _action)


class ParseChoice[TSrc: Equatable[TSrc] #read, TRes] is ParseRule[TSrc,TRes]
  let _children: ReadSeq[ParseRule[TSrc,TRes] box]
  let _action: RuleAction[TSrc,TRes]

  new create(children: ReadSeq[ParseRule[TSrc,TRes] box] box,
             action: RuleAction[TSrc,TRes] = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TRes], start: ParseLoc[TSrc] box): RuleResult[TSrc,TRes] ? =>
    for rule in _children.values() do
      var cur = start.clone()
      match memo.call_with_memo(rule, cur)
      | let r: ParseResult[TSrc,TRes] =>
        return ParseResult[TSrc,TRes].from_action(memo, start, r.next, [r], _action)
      end
    end
    None
