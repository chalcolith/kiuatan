
class ParseChoice[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _children = children
    _action = action
  
  fun name(): String =>
    recover
      let s = String
      s.append("(")
      for child in _children.values() do
        if s.size() > 1 then s.append(" | ") end
        s.append(child.name())
      end
      s.append(")")
      s
    end
  
  fun is_recursive(): Bool =>
    true

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    for rule in _children.values() do
      var cur = start.clone()
      match memo.call_with_memo(rule, cur)?
      | let r: ParseResult[TSrc,TVal] =>
        return ParseResult[TSrc,TVal](memo, start, r.next, [r], _action)
      end
    end
    None
