
use "collections"

class RuleChoice[TSrc: Any #read, TVal = None] is ParseRule[TSrc,TVal]
  """
  Matches one of a list of rules.  Uses PEG committed choice semantics;
  does not backtrack once a choice has matched.
  """

  let _name: String
  let _children: Array[ParseRule[TSrc,TVal] box]
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    children: ReadSeq[ParseRule[TSrc,TVal] box] box
      = Array[ParseRule[TSrc,TVal] box],
    name': String = "",
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _name = name'
    _children = Array[ParseRule[TSrc,TVal] box]
    for child in children.values() do
      _children.push(child)
    end
    _action = action

  fun can_be_recursive(): Bool => true

  fun name(): String => _name

  fun ref unshift(child: ParseRule[TSrc,TVal] box) =>
    _children.unshift(child)

  fun ref push(child: ParseRule[TSrc,TVal] box) =>
    _children.push(child)

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    let s: String trn = recover String end
    if _name != "" then s.append("(" + _name + " = ") end
    s.append("(")
    for (i, child) in _children.pairs() do
      if i > 0 then s.append(" or ") end
      s.append(_child_description(child, call_stack))
    end
    s.append(")")
    if _name != "" then s.append(")") end
    s

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    for rule in _children.values() do
      match memo.parse(rule, start)?
      | let r: ParseResult[TSrc,TVal] =>
        return ParseResult[TSrc,TVal](memo, start, r.next, [r], _action)
      end
    end
    None
