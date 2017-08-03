class ParseNot[TSrc,TVal] is ParseRule[TSrc,TVal]
  """
  Negative lookahead; successfully matches if the child rule does **not** 
  match, without advancing the match position.
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
      None
    else
      ParseResult[TSrc,TVal](memo, start, start, Array[ParseResult[TSrc,TVal]], 
        _action)
    end
