
class ParseState[TSrc,TRes]
  """
  Stores the memo and matcher stack for a particular match.
  """

  let source: ParseSource[TSrc] box
  let start: ParseLoc[TSrc] box

  new create(source': ParseSource[TSrc] box, start': (ParseLoc[TSrc] box | None) = None) ? =>
    source = source'
    start = match start'
    | let s: ParseLoc[TSrc] box => s.clone()
    else
      source.begin()
    end
