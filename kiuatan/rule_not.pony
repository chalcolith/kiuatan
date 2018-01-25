
class RuleNot[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Negative lookahead; successfully matches if the child node does **not**
  match, without advancing the match position.
  """

  let _child: RuleNode[TSrc,TVal] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(child: RuleNode[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _child = child
    _action = action

  fun is_terminal(): Bool =>
    _child.is_terminal()

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    "!(" + _child.description(stack) + ")"

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    match state.parse_with_memo(_child, start, cs)?
    | let r: ParseResult[TSrc,TVal] val =>
      None
    else
      recover
        ParseResult[TSrc,TVal](start, start, this,
          recover Array[ParseResult[TSrc,TVal] val] end, _action)
      end
    end
