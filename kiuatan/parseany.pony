use "collections"

class ParseAny[TSrc,TVal] is ParseRule[TSrc,TVal]
  """
  Matches any single input.
  """

  var _name: String
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _name = ""
    _action = action

  fun name(): String => _name
  fun ref set_name(str: String) => _name = str

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    if _name != "" then
      "(" + _name + " = .)"
    else
      "."
    end

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box):
    (ParseResult[TSrc,TVal] | None) ? =>
    let cur = start.clone()
    if cur.has_next() then
      cur.next()?

      match _action
      | None =>
        ParseResult[TSrc,TVal].from_value(memo, start, cur,
          Array[ParseResult[TSrc,TVal]](), None)
      | let action: ParseAction[TSrc,TVal] val =>
        ParseResult[TSrc,TVal](memo, start, cur,
          Array[ParseResult[TSrc,TVal]](), action)
      end
    else
      None
    end
