
class ParseResult[TSrc,TVal = None]
  """
  Holds information about the result of a successful parse.
  """

  let state: ParseState[TSrc,TVal] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let children: ReadSeq[ParseResult[TSrc,TVal]] box
  let _act: (ParseAction[TSrc,TVal] val | None)
  var _res: (TVal! | None)

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

  fun value(): (TVal! | None) =>
    match _res
    | let res: TVal! =>
      res
    else
      _get_value(None)
    end

  fun _get_value(parent: (ParseActionContext[TSrc,TVal] | None))
    : (TVal! | None)
  =>
    let ctx = ParseActionContext[TSrc,TVal](state, start, next, children,
      parent)
    for child in children.values() do
      ctx.values.push(child._get_value(ctx))
    end

    match _act
    | let act: ParseAction[TSrc,TVal] val =>
      return act(ctx)
    else
      if ctx.values.size() > 0 then
        try
          return ctx.values(ctx.values.size()-1)?
        end
      end
    end
    None


class ParseActionContext[TSrc,TVal]
  """
  Holds the context for a parse action.
  """

  let state: ParseState[TSrc,TVal] box
  let start:  ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let results: ReadSeq[ParseResult[TSrc,TVal]] box
  let values: Array[(TVal! | None)]
  let parent: (ParseActionContext[TSrc,TVal] | None)

  new create(
    state': ParseState[TSrc,TVal] box,
    start':  ParseLoc[TSrc] box,
    next': ParseLoc[TSrc] box,
    results': ReadSeq[ParseResult[TSrc,TVal]] box,
    parent': (ParseActionContext[TSrc,TVal] | None))
  =>
    state = state'
    start = start'
    next = next'
    results = results'
    values = Array[(TVal! | None)]
    parent = parent'

  fun inputs(): ParseLocIterator[TSrc] =>
    start.values(next)

type ParseAction[TSrc,TVal] is {(ParseActionContext[TSrc,TVal] box): (TVal | None)}
