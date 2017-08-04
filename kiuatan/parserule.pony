use "collections"

type ParseRuleCallStack[TSrc,TVal] is
  (ListNode[ParseRule[TSrc,TVal] box] | None)

trait ParseRule[TSrc,TVal]
  """
  A rule in a grammar.
  """

  fun can_be_recursive(): Bool =>
    false

  fun name(): String => ""
  fun ref set_name(str: String) => None

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    "?"

  fun _child_description(child: ParseRule[TSrc,TVal] box,
                         call_stack: ParseRuleCallStack[TSrc,TVal]): String =>
    match call_stack
    | let node: ListNode[ParseRule[TSrc,TVal] box] =>
      var cur = node
      try
        while true do
          if cur()? is child then
            if (child.name() == "") or (child.name() == "?") then
              return "?rule?"
            else
              return child.name()
            end
          end
          if node.has_next() then
            cur = match cur.next()
            | let next: ListNode[ParseRule[TSrc,TVal] box] => next
            else break end
          else
            break
          end
        end
      end
      let top = ListNode[ParseRule[TSrc,TVal] box](this)
      node.prepend(top)
      child.description(top)
    else
      child.description(ListNode[ParseRule[TSrc,TVal] box](this))
    end

  fun parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box):
    (ParseResult[TSrc,TVal] | None) ?

  fun add(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    ParseSequence[TSrc,TVal]([this; other], None)

  fun op_or(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    ParseChoice[TSrc,TVal]([this; other], None)
