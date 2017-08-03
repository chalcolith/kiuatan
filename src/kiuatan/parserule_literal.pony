class ParseLiteral[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  """
  Matches a literal sequence of inputs.
  """

  let _expected: ReadSeq[TSrc] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(expected: ReadSeq[TSrc] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _expected = expected
    _action = action
  
  fun description(): String =>
    try
      recover
        let s = String
        s.append(_expected as this->ReadSeq[U8] box)
        s
      end
    else
      "Literal"
    end

  fun box parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    let cur = start.clone()
    for expected in _expected.values() do
      if not cur.has_next() then return None end
      let actual = cur.next()?
      if expected != actual then return None end
    end

    match _action
    | None => 
      ParseResult[TSrc,TVal].from_value(memo, start, cur, Array[ParseResult[TSrc,TVal]](), None)
    | let action: ParseAction[TSrc,TVal] val =>
      ParseResult[TSrc,TVal](memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end
