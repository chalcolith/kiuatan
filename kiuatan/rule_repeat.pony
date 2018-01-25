
class RuleRepeat[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Matches a number of repetitions of a child node.
  """

  let _child: RuleNode[TSrc,TVal] box
  let _min: USize
  let _max: USize
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    child: RuleNode[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None,
    min: USize = 0, max: USize = USize.max_value())
  =>
    _child = child
    _min = min
    _max = max
    _action = action

  fun is_terminal(): Bool =>
    _child.is_terminal()

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    let desc: String trn = recover String end
    if (_min == 0) and (_max == 1) then
      desc.append("(" + _child.description(stack) + ")?")
    elseif _min == 0 then
      desc.append("(" + _child.description(stack) + ")*")
    elseif _min == 1 then
      desc.append("(" + _child.description(stack) + ")+")
    else
      desc.append("(" + _child.description(stack) + "){"
        + _min.string() + "," + _max.string() + "}")
    end
    desc

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    let results: Array[ParseResult[TSrc,TVal] val] trn =
      recover Array[ParseResult[TSrc,TVal] val] end
    var count: USize = 0
    var cur = start
    while count < _max do
      match state.parse_with_memo(_child, cur, cs)?
      | let r: ParseResult[TSrc,TVal] val =>
        results.push(r)
        cur = r.next
      else
        break
      end
      count = count + 1
    end
    if (count >= _min) then
      let cur': ParseLoc[TSrc] val = cur.clone()
      let subs: Array[ParseResult[TSrc,TVal] val] val = consume results
      recover
        ParseResult[TSrc,TVal](start, cur', this, subs, _action)
      end
    else
      None
    end
