
class RuleError[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Causes the match to fail and records an error message.
  """

  let _msg:
    ( ParseErrorMessage val
    | {(ParseState[TSrc,TVal], ParseLoc[TSrc] val): ParseErrorMessage val} val )

  new create(msg:
    ( ParseErrorMessage val
    | {(ParseState[TSrc,TVal], ParseLoc[TSrc] val):
        ParseErrorMessage val} val ))
  =>
    _msg = msg

  fun is_terminal(): Bool => true

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    "!"

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None)
  =>
    match _msg
    | let str: ParseErrorMessage val =>
      str
    | let f:
      {(ParseState[TSrc,TVal], ParseLoc[TSrc] val): ParseErrorMessage val} val
    =>
      f(state, start)
    end
