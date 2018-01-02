
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

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    match state.parse_with_memo(_child, start)?
    | let r: ParseResult[TSrc,TVal] =>
      None
    else
      ParseResult[TSrc,TVal](state, start, start, this,
        Array[ParseResult[TSrc,TVal]], _action)
    end
