
trait ParseRule[TSrc,TVal]
  """
  A rule in a grammar.
  """

  fun name(): String =>
    "?"

  fun is_recursive(): Bool =>
    false

  fun parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box):
    (ParseResult[TSrc,TVal] | None) ?
