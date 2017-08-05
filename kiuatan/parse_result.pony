
class ParseResult[TSrc: Any #read,TVal = None]
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
          var i: USize = ctx.values.size()
          while i > 0 do
            match ctx.values(i-1)?
            | let v: TVal! => return v
            end
            i = i-1
          end
        end
      end
    end
    None


type ParseAction[TSrc: Any #read, TVal] is
  {(ParseActionContext[TSrc,TVal] box): (TVal | None)}


class ParseActionContext[TSrc: Any #read, TVal]
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

  fun inputs(): Array[box->TSrc] =>
    let arr = Array[box->TSrc]
    for item in start.values(next) do
      arr.push(item)
    end
    arr
