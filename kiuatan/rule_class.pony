
use "collections"

class RuleClass[
  TSrc: (Hashable #read & Equatable[TSrc] #read & Stringable),
  TVal = None] is ParseRule[TSrc,TVal]
  """
  Matches any of a set of inputs.
  """

  var _name: String
  let _expected: Set[TSrc] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(expected: Set[TSrc] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _name = ""
    _expected = expected
    _action = action

  new from_iter(expected: Iterator[TSrc],
               action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _name = ""
    let expected' = Set[TSrc]
    for item in expected do
      expected'.set(item)
    end
    _expected = expected'
    _action = action

  fun name(): String => _name
  fun ref set_name(str: String) => _name = str

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    recover
      let s = String
      if _name != "" then s.append("(" + _name + " = ") end
      s.append("[")
      for item in _expected.values() do
        s.append(item.string())
      end
      s.append("]")
      if _name != "" then s.append(")") end
      s
    end

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    let cur = start.clone()
    if cur.has_next() then
      let actual = cur.next()?

      if _expected.contains(actual) then
        match _action
        | let action: ParseAction[TSrc,TVal] val =>
          return ParseResult[TSrc,TVal](memo, start, cur,
            Array[ParseResult[TSrc,TVal]], action)
        | None =>
          return ParseResult[TSrc,TVal].from_value(memo, start, cur,
            Array[ParseResult[TSrc,TVal]], None)
        end
      end
    end
    None
