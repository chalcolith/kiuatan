
use "collections"

class RuleRepeat[TSrc: Any #read, TVal = None] is ParseRule[TSrc,TVal]
  """
  Matches a number of repetitions of a rule.
  """

  let _child: ParseRule[TSrc,TVal] box
  let _min: USize
  let _max: USize
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    child: ParseRule[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None,
    min: USize = 0, max: USize = USize.max_value())
  =>
    _child = child
    _min = min
    _max = max
    _action = action

  fun can_be_recursive(): Bool =>
    _child.can_be_recursive()

  fun _description(call_stack: List[ParseRule[TSrc,TVal] box]): String =>
    let desc: String trn = recover String end
    if (_min == 0) and (_max == 1) then
      desc.append("(" + _child.description(call_stack) + ")?")
    elseif _min == 0 then
      desc.append("(" + _child.description(call_stack) + ")*")
    elseif _min == 1 then
      desc.append("(" + _child.description(call_stack) + ")+")
    else
      desc.append("(" + _child.description(call_stack) + "){"
        + _min.string() + "," + _max.string() + "}")
    end
    desc

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    let results = Array[ParseResult[TSrc,TVal]]()
    var count: USize = 0
    var cur = start
    while count < _max do
      match state.memoparse(_child, cur)?
      | let r: ParseResult[TSrc,TVal] =>
        results.push(r)
        cur = r.next
      else
        break
      end
      count = count + 1
    end
    if (count >= _min) then
      ParseResult[TSrc,TVal](state, start, cur, results, _action)
    else
      None
    end
