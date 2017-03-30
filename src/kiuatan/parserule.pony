
trait ParseRule[TSrc,TVal]
  """
  A rule in a grammar.
  """

  fun is_recursive(): Bool =>
    false

  fun box parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ?


class ParseAny[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
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
      ParseResult[TSrc,TVal](memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end


class ParseLiteral[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _expected: ReadSeq[TSrc] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(expected: ReadSeq[TSrc] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _expected = expected
    _action = action

  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
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
      ParseResult[TSrc,TVal](memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end


class ParseSequence[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
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
    ParseResult[TSrc,TVal](memo, start, cur, results, _action)


class ParseChoice[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _children = children
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    for rule in _children.values() do
      var cur = start.clone()
      match memo.call_with_memo(rule, cur)
      | let r: ParseResult[TSrc,TVal] =>
        return ParseResult[TSrc,TVal](memo, start, r.next, [r], _action)
      end
    end
    None


class ParseRepeat[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _child: ParseRule[TSrc,TVal] box
  let _min: USize
  let _max: USize
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(child: ParseRule[TSrc,TVal] box, min: USize, max: USize = USize.max_value(), action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _child = child
    _min = min
    _max = max
    _action = action
  
  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    let results = Array[ParseResult[TSrc,TVal]]()
    var count: USize = 0
    var cur = start
    while count < _max do
      match memo.call_with_memo(_child, cur)
      | let r: ParseResult[TSrc,TVal] =>
        results.push(r)
        cur = r.next
      else
        break
      end
      count = count + 1
    end
    if (count >= _min) then
      ParseResult[TSrc,TVal](memo, start, cur, results, _action)
    else
      None
    end
