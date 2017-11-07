
use "collections"

trait ParseRule[TSrc: Any #read, TVal = None]
  """
  A rule in a grammar.
  """

  fun can_be_recursive(): Bool =>
    """
    Should return `true` if the rule or its children might call itself.
    """
    false

  fun name(): String =>
    """
    Returns a diagnostic name for the rule.
    """
    ""

  fun string(): String iso^ =>
    """
    Returns a string representation of the rule, used for debugging.
    """
    description().clone()

  fun description(call_stack: (List[ParseRule[TSrc,TVal] box] | None) = None)
    : String
  =>
    """
    Returns a string representation of the rule, used for debugging.
    """
    let call_stack' =
      match call_stack
      | let list: List[ParseRule[TSrc,TVal] box] =>
        list
      else
        List[ParseRule[TSrc,TVal] box]
      end

    try
      var cur = call_stack'.head()?
      while true do
        try
          let rule: ParseRule[TSrc,TVal] box = cur()?
          if rule is this then
            let name' = this.name()
            if (name' == "") or (name' == "?") then
              return "?rule?"
            else
              return name'
            end
          end
        end

        if cur.has_next() then
          match cur.next()
          | let next: ListNode[ParseRule[TSrc,TVal] box] =>
            cur = next
            continue
          end
        end
        break
      end
    end

    call_stack'.unshift(this)
    let s = _description(call_stack')
    try
      call_stack'.shift()?
    end
    s

  fun _description(call_stack: List[ParseRule[TSrc,TVal] box]): String

  fun parse(state: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
    """
    Attempt to parse the input.
    """

  fun add(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    """
    Allows rule sequences to be created with the `+` operator.
    Note that this will build binary trees of sequence rules, which is not as
    efficient as using a single sequence rule with an array of (possibly more
    than two) children.
    """
    RuleSequence[TSrc,TVal]([this; other])

  fun op_or(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    """
    Allows choices to be created with the `or` operator.
    Note that this will build binary trees of choice rules, which is not as
    efficient as using a single choice rule with an array of (possibly more
    than two) children.
    """
    RuleChoice[TSrc,TVal]([this; other])
