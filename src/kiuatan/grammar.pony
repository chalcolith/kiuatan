type GrammarRuleArg is (None)

trait GrammarRule[TSrc,TRes]
  """
  A rule in a grammar.
  """

  fun parse(memo: ParseState[TSrc,TRes],
            start: ParseLoc[TSrc] box,
            args: (ReadSeq[GrammarRuleArg] | None) = None,
            argStart: USize = 0): (ParseResult[TSrc,TRes] | None) ?


class ParseResult[TSrc,TRes]
  let state: ParseState[TSrc,TRes] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let _act: ({ (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box): TRes } val | None)
  let _res: (TRes! | None)

  new from_value(state': ParseState[TSrc,TRes] box,
                 start': ParseLoc[TSrc] box,
                 next': ParseLoc[TSrc] box,
                 res': (TRes | None)) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    _act = None
    _res = res'

  new from_action(state': ParseState[TSrc,TRes] box,
                  start': ParseLoc[TSrc] box,
                  next': ParseLoc[TSrc] box,
                  act': { (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box): TRes } val) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    _act = act'
    _res = None

  fun box result(): (TRes! | None) =>
    match _res
    | let res: TRes! => res
    else
      match _act
      | let act: { (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box): TRes } val =>
        act(state, start, next)
      else
        None
      end
    end


// class GrammarSeq[TSrc,TRes] is GrammarRule[TSrc,TRes]
//   var _left: GrammarRule[TSrc,TRes]
//   var _right: GrammarRule[TSrc,TRes]
//
//   new create(left: GrammarRule[TSrc,TRes], right: GrammarRule[TSrc,TRes]) =>
//     _left = left
//     _right = right

class GrammarLiteral[TSrc: Equatable[TSrc] #read,TRes] is GrammarRule[TSrc,TRes]
  var _expected: ReadSeq[TSrc] box
  var _action: ({ (ParseState[TSrc,TRes], ParseLoc[TSrc], ParseLoc[TSrc]): TRes } val | None)

  new create(expected: ReadSeq[TSrc] box,
             action: ({ (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box): TRes } val | None) = None) =>
    _expected = expected
    _action = action

  fun parse(memo: ParseState[TSrc,TRes],
            start: ParseLoc[TSrc] box,
            args: (ReadSeq[GrammarRuleArg] box | None) = None,
            argStart: USize = 0)
    : (ParseResult[TSrc,TRes] | None) ? =>

    let cur = start.clone()
    for expected in _expected.values() do
      if not cur.has_next() then return None end
      let actual = cur.next()
      if expected != actual then return None end
    end

    match _action
    | None => ParseResult[TSrc,TRes].from_value(memo, start, cur, None)
    | let action: { (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box): TRes } val =>
      ParseResult[TSrc,TRes].from_action(memo, start, cur, action)
    end
