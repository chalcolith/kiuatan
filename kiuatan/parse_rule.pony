
use "collections"
use "itertools"

class ParseRule[TSrc: Any #read, TVal = None] is RuleNode[TSrc,TVal]
  """
  A named rule that can be memoized and for which left-recursion can be
  detected and handled.
  """

  let _name: String
  var _terminal: (Bool | None)
  var _child: (RuleNode[TSrc,TVal] box | None)
  let _action: (ParseAction[TSrc,TVal] val | None)

  new create(
    n: String,
    child: (RuleNode[TSrc,TVal] box | None) = None,
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _name = n
    _terminal = None
    _child = child
    _action = action

  new terminal(n: String,
    child: (RuleNode[TSrc,TVal] box | None) = None,
    action: (ParseAction[TSrc,TVal] val | None) = None)
  =>
    _name = n
    _terminal = true
    _child = child
    _action = action

  fun name(): String => _name

  fun ref set_child(child: RuleNode[TSrc,TVal] box) =>
    _child = child

  fun is_terminal(): Bool =>
    match _terminal
    | let t: Bool =>
      t
    else
      match _child
      | let ch: RuleNode[TSrc,TVal] box =>
        ch.is_terminal()
      else
        true
      end
    end

  fun _description(stack: Seq[RuleNode[TSrc,TVal] tag]): String =>
    """
    Returns a diagnostic name for the rule.
    """

    for r in Iter[RuleNode[TSrc,TVal] tag](stack.values()).skip(1) do
      if r is this then
        return _name
      end
    end

    match _child
    | let child: RuleNode[TSrc,TVal] box =>
      let s: String trn = recover String end
      s.append("(")
      s.append(_name)
      s.append("=")
      s.append(child.description(stack))
      s.append(")")
      consume s
    else
      "()"
    end

  fun parse(state: ParseState[TSrc,TVal], start: ParseLoc[TSrc] val,
    cs: CallState[TSrc,TVal])
    : (ParseResult[TSrc,TVal] val | ParseErrorMessage val | None) ?
  =>
    match _child
    | let child: RuleNode[TSrc,TVal] box =>
      state.parse_with_memo(child, start, cs)?
    end
