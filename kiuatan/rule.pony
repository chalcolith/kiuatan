
use "collections/persistent"
use "debug"

interface val RuleNode[S, V: Any #share = None]
  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool
  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  fun val _get_action(): (Action[S, V] | None)


class val Rule[S, V: Any #share = None] is RuleNode[S, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """
  let name: String
  var _body: (RuleNode[S, V] box | None)
  let _action: (Action[S, V] | None)

  new create(name': String, body: (RuleNode[S, V] box | None) = None,
    action: (Action[S, V] | None) = None)
  =>
    name = name'
    _body = body
    _action = action

  fun ref set_body(body: RuleNode[S, V] box) =>
    _body = body

  fun eq(other: Rule[S, V]): Bool =>
    this is other

  fun val _is_terminal(stack: List[RuleNode[S, V] tag] =
    Lists[RuleNode[S, V] tag].empty()): Bool
  =>
    match _body
    | let body: val->RuleNode[S, V] =>
      let rule = this
      if stack.exists({(x) => x is rule}) then
        false
      else
        body._is_terminal(stack.prepend(rule))
      end
    else
      true
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let rule = this
    match _body
    | let body: RuleNode[S, V] =>
      let cont' =
        recover
          {(result: Result[S, V], stack': List[_LRRecord[S, V]],
              recur': _LRByRule[S, V])
          =>
            match result
            | let success: Success[S, V] =>
              cont(Success[S, V](rule, success.start, success.next, [success]),
                stack', recur')
            | let failure: Failure[S, V] =>
              cont(Failure[S, V](rule, failure.start, "expected " + rule.name,
                failure), stack', recur')
            end
          }
        end
      parser._parse_with_memo(body, src, loc, stack, recur, consume cont')
    else
      cont(Failure[S, V](this, loc, "rule is empty"), stack, recur)
    end

  fun _get_action(): (Action[S, V] | None) =>
    _action


interface val _Cont[S, V: Any #share]
  fun apply(result: Result[S, V], stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V])


type Result[S, V: Any #share = None] is ( Success[S, V] | Failure[S, V] )
  """
  The result of a parse attempt, either successful or failed.
  """


class val Success[S, V: Any #share = None]
  """
  The result of a successful parse.
  """
  let node: RuleNode[S, V]
  """The rule that matched successfully."""

  let start: Loc[S]
  """The location at which the rule matched."""

  let next: Loc[S]
  """The location one past the end of the match."""

  let children: ReadSeq[Success[S, V]] val
  """Results from child rules' matches."""

  new val create(node': RuleNode[S, V], start': Loc[S], next': Loc[S],
    children': ReadSeq[Success[S, V]] val = recover Array[Success[S, V]](0) end)
  =>
    node = node'
    start = start'
    next = next'
    children = children'

  fun val value(bindings: Bindings[S, V] = Bindings[S, V]): (V | None) =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    _value(0, bindings)._1

  fun val _value(indent: USize, bindings: Bindings[S, V])
    : ((V | None), Bindings[S, V])
  =>
    var bindings' = bindings
    let subvalues = Array[(V | None)]

    // ifdef debug then
    //   match node
    //   | let rule: Rule[S, V] =>
    //     Debug.out(_indent(indent) + "> " + rule.name)
    //   else
    //     Debug.out(_indent(indent) + "> ")
    //   end
    // end

    for child in children.values() do
      (let subval: (V | None), bindings') = child._value(indent + 1, bindings')
      subvalues.push(subval)
    end

    // ifdef debug then
    //   match node
    //   | let rule: Rule[S, V] =>
    //     Debug.out(_indent(indent) + "< " + rule.name)
    //   else
    //     Debug.out(_indent(indent) + "<")
    //   end
    // end

    (let value': (V | None), bindings') =
      match node._get_action()
      | let action: Action[S, V] =>
        action(this, subvalues, bindings')
      else
        var i: USize = subvalues.size()
        var v: (V | None) = None
        while i > 0 do
          let v' = try subvalues(i-1)? end
          if not (v' is None) then
            v = v'
            break
          end
          i = i - 1
        end
        (v, bindings')
      end

    match node
    | let bind: Bind[S, V] =>
      match value'
      | let value'': V =>
        return (value'', bindings'.update(bind.variable, (this, value'')))
      else
        return (value', bindings'.update(bind.variable, (this, None)))
      end
    end
    (value', bindings')

  fun _indent(n: USize): String =>
    recover
      var n' = n * 2
      let s = String(n')
      while (n' = n' - 1) > 0 do
        s.push(' ')
      end
      s
    end

  fun string(): String iso^ =>
    recover
      let s = String
      match node
      | let rule: Rule[S, V] =>
        s.append("Success(" + rule.name + "@[" + start.string() + "," +
          next.string() + "))")
      else
        s.append("Success(_@[" + start.string() + "," + next.string() + "))")
      end
      s
    end


class val Failure[S, V: Any #share = None]
  """
  The result of a failed match.
  """
  let node: RuleNode[S, V]
  let start: Loc[S]
  let message: String
  let inner: (Failure[S, V] | None)

  new val create(node': RuleNode[S, V], start': Loc[S], message': String = "",
    inner': (Failure[S, V] | None) = None)
  =>
    node = node'
    start = start'
    message = message'
    inner = inner'

  fun get_message(): String =>
    recover
      let s = String
      s.append("[")
      if message.size() > 0 then
        s.append(message)
      end
      match inner
      | let inner': Failure[S, V] =>
        if message.size() > 0 then
          s.append(": ")
        end
        s.append(inner'.get_message())
      end
      s.append("]")
      s
    end

  fun string(): String iso^ =>
    recover
      let s = String
      match node
      | let rule: Rule[S, V] =>
        s.append("Failure(" + rule.name + "@" + start.string() + ")")
      else
        s.append("Failure(_@" + start.string() + ")")
      end
      s
    end


class tag Variable
type Bindings[S, V: Any #share] is MapIs[Variable, (Success[S, V], (V | None))]

interface val Action[S, V: Any #share]
  """
  Used to assemble a custom result value.
  """
  fun apply(result: Success[S, V], child_values: Array[(V | None)],
    bindings: Bindings[S, V]): ((V | None), Bindings[S, V])
