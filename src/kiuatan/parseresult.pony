
type ParseAction[TSrc,TVal] is {
  (ParseState[TSrc,TVal] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box, ReadSeq[ParseResult[TSrc,TVal] box] box): TVal
}

class ParseResult[TSrc,TVal]
  let state: ParseState[TSrc,TVal] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let children: ReadSeq[ParseResult[TSrc,TVal]] box
  let _act: (ParseAction[TSrc,TVal] val | None)
  let _res: (TVal! | None)

  new from_value(state': ParseState[TSrc,TVal] box,
                 start': ParseLoc[TSrc] box,
                 next': ParseLoc[TSrc] box,
                 children': ReadSeq[ParseResult[TSrc,TVal]] box,
                 res': (TVal | None)) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    children = children'
    _act = None
    _res = res'

  new from_action(state': ParseState[TSrc,TVal] box,
                  start': ParseLoc[TSrc] box,
                  next': ParseLoc[TSrc] box,
                  children': ReadSeq[ParseResult[TSrc,TVal]] box,
                  act': (ParseAction[TSrc,TVal] val | None)) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    children = children'
    _act = act'
    _res = None

  fun box value(): (TVal! | None) =>
    match _res
    | let res: TVal! => res
    else
      match _act
      | let act: ParseAction[TSrc,TVal] val =>
        act(state, start, next, children)
      else
        None
      end
    end
