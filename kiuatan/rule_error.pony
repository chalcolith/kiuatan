
use "collections"
use "itertools"

class RuleError[TSrc: Any #read, TVal = None] is ParseRule[TSrc,TVal]
  """
  Causes the match to fail and records an error message.
  """

  let _msg:
    ( ParseErrorMessage
    | {(ParseState[TSrc,TVal], ParseLoc[TSrc] box): ParseErrorMessage} val )

  new create(msg: ParseErrorMessage) =>
    _msg = msg

  new from_state(f:
    {(ParseState[TSrc,TVal], ParseLoc[TSrc] box): ParseErrorMessage} val)
  =>
    _msg = f

  fun _description(call_stack: List[ParseRule[TSrc,TVal] box]): String =>
    "!"

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None)
  =>
    match _msg
    | let str: ParseErrorMessage =>
      str
    | let f:
      {(ParseState[TSrc,TVal], ParseLoc[TSrc] box): ParseErrorMessage} val
    =>
      f(state, start)
    end
