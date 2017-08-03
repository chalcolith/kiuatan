class ParseChoice[TSrc, TVal] is ParseRule[TSrc,TVal]
  """
  Matches one of a list of rules.  Uses PEG committed choice semantics;
  does not backtrack once a choice has matched.
  """

  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _children = children
    _action = action
  
  fun description(): String =>
    recover
      let s = String
      s.append("(")
      for child in _children.values() do
        if s.size() > 1 then s.append(" | ") end
        s.append(child.description())
      end
      s.append(")")
      s
    end
  
  fun can_be_recursive(): Bool =>
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
