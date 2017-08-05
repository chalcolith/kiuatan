
use "collections"

class RuleAny[TSrc: Any #read, TVal = None] is ParseRule[TSrc,TVal]
  """
  Matches any single input.
  """

  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _action = action

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    "."

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    let cur = start.clone()
    if cur.has_next() then
      cur.next()?

      match _action
      | None =>
        ParseResult[TSrc,TVal].from_value(memo, start, cur,
          Array[ParseResult[TSrc,TVal]], None)
      | let action: ParseAction[TSrc,TVal] val =>
        ParseResult[TSrc,TVal](memo, start, cur,
          Array[ParseResult[TSrc,TVal]], action)
      end
    else
      None
    end
