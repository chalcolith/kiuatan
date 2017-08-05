
use "collections"

class RuleAnd[TSrc,TVal = None] is ParseRule[TSrc,TVal]
  """
  Lookahead; matches its child rule without advancing the match position.

  Discards any results of the child match.
  """

  let _child: ParseRule[TSrc,TVal] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    child: ParseRule[TSrc,TVal] box,
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _child = child
    _action = action

  fun can_be_recursive(): Bool => true

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    "&(" + _child_description(_child, call_stack) + ")"

  fun parse(memo: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?
  =>
    match memo.parse(_child, start)?
    | let r: ParseResult[TSrc,TVal] =>
      ParseResult[TSrc,TVal](memo, start, start, Array[ParseResult[TSrc,TVal]],
        _action)
    else
      None
    end
