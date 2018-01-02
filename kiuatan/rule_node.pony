
use "collections"

primitive _CallStack[TSrc: Any #read, TVal = None]
  // This gets around the trait use bug.
  fun apply(): Seq[RuleNode[TSrc,TVal] tag] =>
    List[RuleNode[TSrc,TVal] tag]

trait RuleNode[TSrc: Any #read, TVal = None]
  """
  A node in a rule in a grammar.
  """

  fun is_terminal(): Bool

  fun string(): String iso^ =>
    """
    Returns a string representation of the node, used for debugging.
    """
    description().clone()

  fun description(stack: (Seq[RuleNode[TSrc,TVal] tag] | None) = None)
    : String
  =>
    """
    Returns a string representation of the node, used for debugging.
    """
    let stack' = 
      match stack
      | let cs: Seq[RuleNode[TSrc,TVal] tag] =>
        cs
      else
        _CallStack[TSrc,TVal]()
      end

    var result = "?"
    try
      stack'.unshift(this)
      result = _description(stack')
    then
      try
        stack'.shift()
      end
    end
    result

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String

  fun parse(state: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
    """
    Attempt to parse the input.
    """

  fun add(other: RuleNode[TSrc,TVal]): RuleNode[TSrc,TVal] =>
    """
    Allows node sequences to be created with the `+` operator.
    Note that this will build binary trees of sequence nodes, which is not as
    efficient as using a single sequence node with an array of (possibly more
    than two) children.
    """
    RuleSequence[TSrc,TVal]([this; other])

  fun op_or(other: RuleNode[TSrc,TVal]): RuleNode[TSrc,TVal] =>
    """
    Allows choices to be created with the `or` operator.
    Note that this will build binary trees of choice nodes, which is not as
    efficient as using a single choice node with an array of (possibly more
    than two) children.
    """
    RuleChoice[TSrc,TVal]([this; other])
