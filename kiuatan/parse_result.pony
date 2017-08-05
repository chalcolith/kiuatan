
class ParseResult[TSrc,TVal = None]
  """
  Holds information about the result of a successful parse.
  """

  let state: ParseState[TSrc,TVal] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let children: ReadSeq[ParseResult[TSrc,TVal]] box
  let _act: (ParseAction[TSrc,TVal] val | None)
  let _res: (TVal! | None)

  new create(state': ParseState[TSrc,TVal] box,
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

  fun box value(): (TVal! | None) =>
    match _res
    | let res: TVal! => res
    else
      match _act
      | let act: ParseAction[TSrc,TVal] val =>
        act(ParseActionContext[TSrc,TVal](state, start, next, children))
      else
        None
      end
    end


class box ParseActionContext[TSrc,TVal]
  """
  Holds the context for a parse action.
  """

  let state: ParseState[TSrc,TVal] box
  let start:  ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let results: ReadSeq[ParseResult[TSrc,TVal] box] box

  new create(state': ParseState[TSrc,TVal] box,
             start':  ParseLoc[TSrc] box,
             next': ParseLoc[TSrc] box,
             results': ReadSeq[ParseResult[TSrc,TVal] box] box) =>
    state = state'
    start = start'
    next = next'
    results = results'

  fun inputs(): ParseLocIterator[TSrc] =>
    start.values(next)

type ParseAction[TSrc,TVal] is { (ParseActionContext[TSrc,TVal]): TVal }
