use "collections"

class ParseAnd[TSrc,TVal] is ParseRule[TSrc,TVal]
  """
  Lookahead; matches its child rule without advancing the match position.

  Discards any results of the child match.
  """

  var _name: String
  let _child: ParseRule[TSrc,TVal] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(child: ParseRule[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _child = child
    _action = action
    _name = "?"

  fun can_be_recursive(): Bool => true

  fun name(): String => _name
  fun ref set_name(str: String) => _name = str

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    if _name != "" then
      "(" + _name + " = &(" + _child_description(_child, call_stack) + "))"
    else
      "&(" + _child_description(_child, call_stack) + ")"
    end

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box):
    (ParseResult[TSrc,TVal] | None) ? =>
    match memo.parse(_child, start)?
    | let r: ParseResult[TSrc,TVal] =>
      ParseResult[TSrc,TVal](memo, start, start, Array[ParseResult[TSrc,TVal]],
        _action)
    else
      None
    end
