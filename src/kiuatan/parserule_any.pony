
class ParseAny[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _action = action
  
  fun name(): String =>
    "."

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    let cur = start.clone()
    if cur.has_next() then 
      cur.next()?
    else
      return None 
    end

    match _action
    | None => 
      ParseResult[TSrc,TVal].from_value(memo, start, cur, Array[ParseResult[TSrc,TVal]](), None)
    | let action: ParseAction[TSrc,TVal] val =>
      ParseResult[TSrc,TVal](memo, start, cur, Array[ParseResult[TSrc,TVal]](), action)
    end
