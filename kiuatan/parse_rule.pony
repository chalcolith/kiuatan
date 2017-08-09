
use "collections"
use "debug"

class Wombat
  new create() =>
    Debug.out("wombat!")

type ParseRuleCallStack[TSrc: Any #read, TVal] is
  (ListNode[ParseRule[TSrc,TVal] box] | None)

trait ParseRule[TSrc: Any #read, TVal = None]
  """
  A rule in a grammar.
  """

  fun can_be_recursive(): Bool =>
    false

  fun name(): String => ""

  fun string(): String iso^ =>
    description().clone()

  fun description(call_stack: ParseRuleCallStack[TSrc,TVal] = None): String =>
    "?"

  fun _child_description(
    call_stack: ParseRuleCallStack[TSrc,TVal],
    child: ParseRule[TSrc,TVal] box)
    : String
  =>
    //Debug.out("_child_description " + this.name() + " " + child.name())
    let new_stack =
      match call_stack
      | let node: ListNode[ParseRule[TSrc,TVal] box] =>
        //Debug.out(" found node")
        var cur = node
        while true do
          try
            match cur()?
            | let rule: ParseRule[TSrc,TVal] box =>
              //Debug.out(" node has rule " + rule.name())
              if rule is this then
                //Debug.out(" rule is this")
                let name' = this.name()
                if (name' == "") or (name' == "?") then
                  return "?rule?"
                else
                  return name'
                end
              else
                //Debug.out(" rule is NOT this")
                None
              end
            else
              //Debug.out(" node has no rule")
              break
            end
          else
            //Debug.out(" error")
            break
          end
          if cur.has_next() then
            //Debug.out(" cur has next ")
            cur =
              match cur.next()
              | let next: ListNode[ParseRule[TSrc,TVal] box] =>
                //Debug.out("  next is node")
                next
              else
                //Debug.out("  next is None")
                break
              end
          else
            //Debug.out(" cur does NOT have next")
            break
          end
        end

        //Debug.out(" pushing this on top of stack")
        let top = ListNode[ParseRule[TSrc,TVal] box](this)
        top.append(node)
        top
      else
        //Debug.out(" starting stack with this")
        ListNode[ParseRule[TSrc,TVal] box](this)
      end
    //Debug.out(" child.description")
    child.description(new_stack)

  fun parse(memo: ParseState[TSrc,TVal] ref, start: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | None) ?

  fun add(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    RuleSequence[TSrc,TVal]([this; other])

  fun op_or(other: ParseRule[TSrc,TVal]): ParseRule[TSrc,TVal] =>
    RuleChoice[TSrc,TVal]([this; other])
