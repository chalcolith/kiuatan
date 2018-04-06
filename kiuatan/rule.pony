
use "collections/persistent"

interface val RuleNode[S, V = None]
  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool
  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  fun val _get_action(): Action[S, V]


class val Rule[S, V = None] is RuleNode[S, V]
  """
  Represents a named grammar rule.  Memoization and left-recursion handling happens per named `Rule`.
  """
  let name: String
  var _body: (RuleNode[S, V] box | None)
  let _action: Action[S, V]

  new create(name': String, body: (RuleNode[S, V] box | None),
    action: Action[S, V] = Rules[S, V].defaultAction())
  =>
    name = name'
    _body = body
    _action = action

  fun ref set_body(body: RuleNode[S, V] box) =>
    _body = body

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
    match _body
    | let body: val->RuleNode[S, V] =>
      parser._parse_with_memo(body, src, loc, stack, recur, cont)
    else
      cont(Failure[S, V](this, loc, "rule is empty"), stack, recur)
    end

  fun _get_action(): Action[S, V] =>
    _action


interface val _Cont[S, V]
  fun apply(result: Result[S, V], stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V])


type Result[S, V = None] is ( Success[S, V] | Failure[S, V] )
  """
  The result of a parse attempt, either successful or failed.
  """


class val Success[S, V = None]
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

  fun val value(): (V^ | None) =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    let cvs: Array[(V | None)] val =
      recover
        let cvs' = Array[(V | None)](children.size())
        for child in children.values() do
          cvs'.push(child.value())
        end
        cvs'
      end
    node._get_action()(ActionContext[S, V](this, cvs))

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

class val Failure[S, V = None]
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


interface val Action[S, V]
  """
  Used to assemble a custom result value.
  """
  fun apply(ctx: ActionContext[S, V]): (V^ | None)


class iso ActionContext[S, V]
  let result: Success[S, V]
  let child_values: Array[(V | None)] val

  new iso create(result': Success[S, V],
    child_values': Array[(V | None)] val)
  =>
    result = result'
    child_values = child_values'
