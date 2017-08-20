
use "itertools"

class ParseResult[TSrc: Any #read,TVal = None]
  """
  Holds information about the result of a successful parse. The result includes
  a child result for each child rule of the grammar.
  """
  let state: ParseState[TSrc,TVal] box
  let start: ParseLoc[TSrc] box
  let next: ParseLoc[TSrc] box
  let rule: ParseRule[TSrc,TVal] box
  let results: ReadSeq[ParseResult[TSrc,TVal]] box
  let _res: (TVal! | ParseAction[TSrc,TVal] val | None)

  new create(
    state': ParseState[TSrc,TVal] box,
    start': ParseLoc[TSrc] box,
    next': ParseLoc[TSrc] box,
    rule': ParseRule[TSrc,TVal] box,
    results': ReadSeq[ParseResult[TSrc,TVal]] box,
    res': (TVal | ParseAction[TSrc,TVal] val | None))
  =>
    state = state'
    start = start'.clone()
    next = next'.clone()
    rule = rule'
    results = results'
    _res = res'

  fun inputs(): Array[box->TSrc] iso^ =>
    """
    Returns an array of the input values that were matched to get this result.
    Allocates a new array and copies the input items, so call this sparingly.
    """
    recover
      Iter[box->TSrc](start.values(next)).collect(Array[box->TSrc])
    end

  fun value(): (TVal! | None) =>
    """
    Assembles a custom value by traversing the tree of results in post-order,
    calling rule actions if they are present.

    If a rule does not contain an action, its result's value is by default the
    last non-`None` value of its children.
    """
    _get_value(None)

    match _res
    | let res: TVal! =>
      res
    else
      _get_value(None)
    end

  fun _get_value(parent: (ParseActionContext[TSrc,TVal] | None))
    : (TVal! | None)
  =>
    let ctx = ParseActionContext[TSrc,TVal](parent, this)
    for child in results.values() do
      ctx.children.push(child._get_value(ctx))
    end

    match _res
    | let res: TVal! =>
      res
    | let act: ParseAction[TSrc,TVal] val =>
      act(ctx)
    else
      var last: (TVal! | None) = None
      for v in ctx.children.values() do
        match v
        | let v': TVal! =>
          last = v'
        end
      end
      last
    end


type ParseAction[TSrc: Any #read, TVal] is
  {(ParseActionContext[TSrc,TVal] box): (TVal | None)}
  """
  A parse action is used to assemble custom results from the result of a parse.
  """


class ParseActionContext[TSrc: Any #read, TVal]
  """
  Holds the context for a parse action.  It contains the following fields:
  - `parent`: the parent rule's action's context (the parent's `values` field
    will **not** yet be populated).
  - `result`: the parse result for which this value is being generated.
  - `children`: the values obtained from child rules' actions.
  """

  let parent: (ParseActionContext[TSrc,TVal] | None)
  let result: ParseResult[TSrc,TVal] box
  let children: Array[(TVal! | None)]

  new create(
    parent': (ParseActionContext[TSrc,TVal] | None),
    result': ParseResult[TSrc,TVal] box)
  =>
    parent = parent'
    result = result'
    children = Array[(TVal! | None)]
