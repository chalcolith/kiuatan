
class RuleChoice[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Matches one of a list of child nodes.  Uses PEG committed choice semantics;
  does not backtrack once a choice has matched.
  """

  let _children: Array[RuleNode[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    children: ReadSeq[RuleNode[TSrc,TVal] box] box
      = Array[RuleNode[TSrc,TVal] box],
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _children = Array[RuleNode[TSrc,TVal] box]
    for child in children.values() do
      _children.push(child)
    end
    _action = action

  fun is_terminal(): Bool => false

  fun ref unshift(child: RuleNode[TSrc,TVal] box) =>
    _children.unshift(child)

  fun ref push(child: RuleNode[TSrc,TVal] box) =>
    _children.push(child)

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    let s: String trn = recover String end
    s.append("(")
    for (i, child) in _children.pairs() do
      if i > 0 then s.append(" or ") end
      s.append(child.description(stack))
    end
    s.append(")")
    s

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    for child in _children.values() do
      match state.parse_with_memo(child, start, cs)?
      | let r: ParseResult[TSrc,TVal] val =>
        return // early return
          recover
            ParseResult[TSrc,TVal](start, r.next, this, [r], _action)
          end
      end
    end
