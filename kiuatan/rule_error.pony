
class RuleError[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Causes the match to fail and records an error message.
  """

  let _msg:
    ( ParseErrorMessage
    | {(ParseState[TSrc,TVal], ParseLoc[TSrc] box): ParseErrorMessage} val )

  new create(msg:
    ( ParseErrorMessage
    | {(ParseState[TSrc,TVal], ParseLoc[TSrc] box): ParseErrorMessage} val))
  =>
    _msg = msg

  fun is_terminal(): Bool => true

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
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
