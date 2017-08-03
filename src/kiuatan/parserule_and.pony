class ParseAnd[TSrc,TVal] is ParseRule[TSrc,TVal]
  """
  Lookahead; matches its child rule without advancing the match position.
  """

  let _child: ParseRule[TSrc,TVal] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(child: ParseRule[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _child = child
    _action = action
  
  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): 
    (ParseResult[TSrc,TVal] | None) ? =>
    match memo.call_with_memo(_child, start)?
    | let r: ParseResult[TSrc,TVal] =>
      ParseResult[TSrc,TVal](memo, start, start, Array[ParseResult[TSrc,TVal]],
        _action)
    else
      None
    end
