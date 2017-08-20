
use "collections"

class RuleAny[TSrc: Any #read, TVal = None] is ParseRule[TSrc,TVal]
  """
  Matches any single input.
  """

  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _action = action

  fun _description(call_stack: List[ParseRule[TSrc,TVal] box]): String =>
    "."

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let cur = start.clone()
    if cur.has_next() then
      cur.next()?

      ParseResult[TSrc,TVal](state, start, cur, this,
        Array[ParseResult[TSrc,TVal]], _action)
    else
      None
    end
