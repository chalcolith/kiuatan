trait ParseRule[TSrc,TVal]
  """
  A rule in a grammar.
  """

  fun description(): String =>
    "?"

  fun can_be_recursive(): Bool =>
    false

  fun parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box):
    (ParseResult[TSrc,TVal] | None) ?

  fun add(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    ParseSequence[TSrc,TVal]([this; other], None)
  
  fun op_or(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    ParseChoice[TSrc,TVal]([this; other], None)
