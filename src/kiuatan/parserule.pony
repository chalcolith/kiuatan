trait ParseRule[TSrc,TRes]
  """
  A rule in a grammar.
  """

  fun is_recursive(): Bool =>
    false

  fun box parse(memo: ParseState[TSrc,TRes] ref, start: ParseLoc[TSrc] ref): (ParseResult[TSrc,TRes] | None) ?


class ParseLiteral[TSrc: Equatable[TSrc] #read, TRes] is ParseRule[TSrc,TRes]
  var _expected: ReadSeq[TSrc] box
  var _action: (ParseAction[TSrc,TRes] val | None)

  new create(expected: ReadSeq[TSrc] box,
             action: (ParseAction[TSrc,TRes] val | None) = None) =>
    _expected = expected
    _action = action

  fun box parse(memo: ParseState[TSrc,TRes], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TRes] | None) ? =>
    let cur = start.clone()
    for expected in _expected.values() do
      if not cur.has_next() then return None end
      let actual = cur.next()
      if expected != actual then return None end
    end

    match _action
    | None => ParseResult[TSrc,TRes].from_value(memo, start, cur, Array[ParseResult[TSrc,TRes]](), None)
    | let action: ParseAction[TSrc,TRes] val =>
      ParseResult[TSrc,TRes].from_action(memo, start, cur, Array[ParseResult[TSrc,TRes]](), action)
    end
