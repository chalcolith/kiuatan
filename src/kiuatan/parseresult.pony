type ParseAction[TSrc,TRes] is {
  (ParseState[TSrc,TRes] box, ParseLoc[TSrc] box, ParseLoc[TSrc] box, ReadSeq[ParseResult[TSrc,TRes] box] box): TRes
}

class ParseResult[TSrc,TRes]
  let state: ParseState[TSrc,TRes] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let children: ReadSeq[ParseResult[TSrc,TRes]] box
  let _act: (ParseAction[TSrc,TRes] val | None)
  let _res: (TRes! | None)

  new from_value(state': ParseState[TSrc,TRes] box,
                 start': ParseLoc[TSrc] box,
                 next': ParseLoc[TSrc] box,
                 children': ReadSeq[ParseResult[TSrc,TRes]] box,
                 res': (TRes | None)) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    children = children'
    _act = None
    _res = res'

  new from_action(state': ParseState[TSrc,TRes] box,
                  start': ParseLoc[TSrc] box,
                  next': ParseLoc[TSrc] box,
                  children': ReadSeq[ParseResult[TSrc,TRes]] box,
                  act': (ParseAction[TSrc,TRes] val | None)) =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    children = children'
    _act = act'
    _res = None

  fun box value(): (TRes! | None) =>
    match _res
    | let res: TRes! => res
    else
      match _act
      | let act: ParseAction[TSrc,TRes] val =>
        act(state, start, next, children)
      else
        None
      end
    end
