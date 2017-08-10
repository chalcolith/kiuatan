
use "collections"

trait ParseRule[TSrc: Any #read, TVal = None]
  """
  A rule in a grammar.
  """

  fun can_be_recursive(): Bool =>
    false

  fun name(): String =>
    ""

  fun string(): String iso^ =>
    description().clone()

  fun description(
    call_stack: (List[ParseRule[TSrc,TVal] box] | None) = None)
    : String
  =>
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
          match cur()?
          | let rule: ParseRule[TSrc,TVal] box =>
            if rule is this then
              let name' = this.name()
              if (name' == "") or (name' == "?") then
                return "?rule?"
              else
                return name'
              end
            end
          else
            break
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

  fun parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?

  fun add(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    RuleSequence[TSrc,TVal]([this; other])

  fun op_or(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    RuleChoice[TSrc,TVal]([this; other])
