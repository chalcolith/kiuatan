
use "collections"

class RuleClass[
  TSrc: (Hashable #read & Equatable[TSrc] #read & Stringable #read),
  TVal = None] is RuleNode[TSrc,TVal]
  """
  Matches any of a set of inputs.
  """

  let _expected: Set[TSrc] box
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(expected: Set[TSrc] box,
             action: (ParseAction[TSrc,TVal] val | None) = None) =>
    _expected = expected
    _action = action

  new from_iter(
    expected: Iterator[TSrc],
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    let expected' = Set[TSrc]
    for item in expected do
      expected'.set(item)
    end
    _expected = expected'
    _action = action

  fun is_terminal(): Bool => true

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    recover
      let s = String
      s.append("[")
      for item in _expected.values() do
        s.append(item.string())
      end
      s.append("]")
      s
    end

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] box,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let cur = start.clone()
    if cur.has_next() then
      let actual = cur.next()?
      if _expected.contains(actual) then
        ParseResult[TSrc,TVal](state, start, cur, this,
          Array[ParseResult[TSrc,TVal]], _action)
      end
    end
