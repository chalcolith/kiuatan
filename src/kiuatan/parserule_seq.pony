
class ParseSequence[TSrc,TVal] is ParseRule[TSrc,TVal]
  let _name: String
  let _children: ReadSeq[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(name': String,
             children: ReadSeq[ParseRule[TSrc,TVal] box] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _name = name'
    _children = children
    _action = action
  
  fun name(): String =>
    if _name.size() > 0 then
      _name
    else
      recover val
        let s = String
        s.append("(")
        for child in _children.values() do
          if s.size() > 1 then s.append(" + ") end
          s.append(child.name())
        end
        s.append(")")
        s
      end
    end
  
  fun is_recursive(): Bool =>
    true

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): (ParseResult[TSrc,TVal] | None) ? =>
    let results = Array[ParseResult[TSrc,TVal]](_children.size())
    var cur = start
    for rule in _children.values() do
      match memo.call_with_memo(rule, cur)?
      | let r: ParseResult[TSrc,TVal] =>
        results.push(r)
        cur = r.next
      else
        return None
      end
    end
    ParseResult[TSrc,TVal](memo, start, cur, results, _action)
