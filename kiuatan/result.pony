use per = "collections/persistent"

type Result[S, D: Any #share = None, V: Any #share = None]
  is (Success[S, D, V] | Failure[S, D, V])
  """
  The result of a parse attempt, either successful or failed.
  """

class val Success[S, D: Any #share = None, V: Any #share = None]
  """
  The result of a successful parse.
  """

  let node: RuleNode[S, D, V]
  """The rule that matched successfully."""

  let start: Loc[S]
  """The location at which the rule matched."""

  let next: Loc[S]
  """The location one past the end of the match."""

  let children: ReadSeq[Success[S, D, V]] val
  """Results from child rules' matches."""

  let data: D

  new val create(
    node': RuleNode[S, D, V],
    start': Loc[S],
    next': Loc[S],
    data': D,
    children': ReadSeq[Success[S, D, V]] val =
      recover val Array[Success[S, D, V]] end)
  =>
    node = node'
    start = start'
    next = next'
    data = data'
    children = children'

  fun val _values(bindings: Bindings[S, D, V] = Bindings[S, D, V])
    : ReadSeq[V] val
  =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    match _values_aux(0, bindings)
    | (let result_values: Array[V] val, _) =>
      result_values
    else
      []
    end

  fun val _values_aux(indent: USize, bindings: Bindings[S, D, V])
    : ((Array[V] val | None), Bindings[S, D, V])
  =>
    // collect values from child results
    var bindings' = bindings
    var result_values: (Array[V] val | None) =
      recover val
        var result_values': (Array[V] | None) = None
        for child in children.values() do
          (let child_result_values: (Array[V] val | None), bindings') =
            child._values_aux(indent + 1, bindings')

          match child_result_values
          | let crv: Array[V] val if crv.size() > 0 =>
            result_values' =
              match result_values'
              | let rv': Array[V] =>
                rv' .> append(crv)
              else
                Array[V](crv.size()) .> append(crv)
              end
          end
        end
        result_values'
      end

    // now run node's action, if any
    match node.get_action()
    | let action: Action[S, D, V] =>
      let result_values' =
        match result_values
        | let rv': Array[V] val =>
          rv'
        else
          recover val Array[V] end
        end
      (let value, bindings') = action(this, result_values', bindings')
      match value
      | let value': V =>
        result_values = recover val [ value' ] end
      else
        result_values = None
      end
    end

    // now bind variables
    match node
    | let bind: Bind[S, D, V] =>
      let result_values' =
        match result_values
        | let rv': Array[V] val =>
          rv'
        else
          recover val Array[V] end
        end
      bindings' = bindings'.add(bind.variable, (this, result_values'))
    end
    (result_values, bindings')

  fun _indent(n: USize): String =>
    recover
      var n' = n * 2
      let s = String(n')
      while (n' = n' - 1) > 0 do
        s.push(' ')
      end
      s
    end

  fun eq(that: box->Success[S, D, V]): Bool =>
    (this.node is that.node)
      and (this.start == that.start)
      and (this.next == that.next)

  fun string(): String iso^ =>
    recover
      let s = String
      match node
      | let rule: NamedRule[S, D, V] =>
        s.append("Success(" + rule.name + "@[" + start.string() + "," +
          next.string() + "))")
      else
        s.append("Success(@[" + start.string() + "," + next.string() + "))")
      end
      s
    end

class val Failure[S, D: Any #share = None, V: Any #share = None]
  """
  The result of a failed match.
  """

  let node: RuleNode[S, D, V]
  let start: Loc[S]
  let message: (String | None)
  let inner: (Failure[S, D, V] | None)
  let data: D

  new val create(
    node': RuleNode[S, D, V],
    start': Loc[S],
    data': D,
    message': (String | None) = None,
    inner': (Failure[S, D, V] | None) = None)
  =>
    node = node'
    start = start'
    data = data'
    message = message'
    inner = inner'

  fun get_message(): String =>
    recover
      let s = String
      let message' = match message | let m: String => m else "" end
      if message'.size() > 0 then
        s.append("[")
        s.append(message')
      end
      match inner
      | let inner': Failure[S, D, V] =>
        let inner_msg = inner'.get_message()
        if inner_msg.size() > 0 then
          if message'.size() > 0 then
            s.append(": ")
          end
          s.append(inner_msg)
        end
      end
      if (message'.size() > 0) then
        s.append("]")
      end
      s
    end

  fun string(): String iso^ =>
    recover
      let s = String
      match node
      | let rule: NamedRule[S, D, V] =>
        s.append("Failure(" + rule.name + "@" + start.string() + ")")
      else
        s.append("Failure(@" + start.string() + ")")
      end
      s
    end
