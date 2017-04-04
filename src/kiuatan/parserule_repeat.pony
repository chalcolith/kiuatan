
class ParseRepeat[TSrc: Equatable[TSrc] #read, TVal] is ParseRule[TSrc,TVal]
  let _child: ParseRule[TSrc,TVal] box
  let _min: USize
  let _max: USize
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(child: ParseRule[TSrc,TVal] box, min: USize, max: USize = USize.max_value(), 
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _child = child
    _min = min
    _max = max
    _action = action
  
  fun name(): String =>
    if (_min == 0) and (_max == 1) then
      _child.name() + "?"
    elseif _min == 0 then
      _child.name() + "*"
    elseif _min == 1 then
      _child.name() + "+"
    else
      _child.name() + "{" + _min.string() + 
        "," + _max.string() + "}"
    end
  
  fun is_recursive(): Bool =>
    true
      
  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box): 
    (ParseResult[TSrc,TVal] | None) ? =>
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
