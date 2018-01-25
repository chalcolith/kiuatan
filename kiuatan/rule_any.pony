
class RuleAny[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Matches any single input.
  """

  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _action = action

  fun is_terminal(): Bool => true

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    "."

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    let cur = start.clone()
    if cur.has_next() then
      cur.next()?
      let cur': ParseLoc[TSrc] val = cur.clone()
      recover
        ParseResult[TSrc,TVal](start, cur', this,
          recover Array[ParseResult[TSrc,TVal] val] end, _action)
      end
    else
      None
    end
