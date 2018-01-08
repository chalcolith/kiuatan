
class RuleSequence[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  Matches a sequence of child nodes.
  """

  let _children: Array[RuleNode[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    children: ReadSeq[RuleNode[TSrc,TVal] box]
      = Array[RuleNode[TSrc,TVal] box],
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _children = Array[RuleNode[TSrc,TVal] box]
    for child in children.values() do
      _children.push(child)
    end
    _action = action

  fun is_terminal(): Bool =>
    false

  fun ref unshift(child: RuleNode[TSrc,TVal] box) =>
    _children.unshift(child)

  fun ref push(child: RuleNode[TSrc,TVal] box) =>
    _children.push(child)

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    let s: String trn = recover String end
    s.append("(")
    for (i, child) in _children.pairs() do
      if i > 0 then s.append(" + ") end
      s.append(child.description(stack))
    end
    s.append(")")
    s

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    let results = Array[ParseResult[TSrc,TVal]](_children.size())
    var cur = start
    for child in _children.values() do
      match state.parse_with_memo(child, cur, cs)?
      | let res: ParseResult[TSrc,TVal] =>
        results.push(res)
        cur = res.next
      else
        return None
      end
    end
    ParseResult[TSrc,TVal](state, start, cur, this, results, _action)
