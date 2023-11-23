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

  let node: RuleNode[S, D, V] val
  """The rule that matched successfully."""

  let start: Loc[S]
  """The location at which the rule matched."""

  let next: Loc[S]
  """The location one past the end of the match."""

  let children: ReadSeq[Success[S, D, V]] val
  """Results from child rules' matches."""

  new val create(
    node': RuleNode[S, D, V] val,
    start': Loc[S],
    next': Loc[S],
    children': ReadSeq[Success[S, D, V]] val =
      recover val Array[Success[S, D, V]] end)
  =>
    node = node'
    start = start'
    next = next'
    children = children'

  fun val _values(data: D, bindings: Bindings[S, D, V] = Bindings[S, D, V])
    : ReadSeq[V] val
  =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    match _values_aux(data, 0, bindings)
    | (let result_values: Array[V] val, _) =>
      result_values
    else
      []
    end

  fun val _values_aux(data: D, indent: USize, bindings: Bindings[S, D, V])
    : ((Array[V] val | None), Bindings[S, D, V])
  =>
    // collect values from child results
    var bindings' = bindings
    var result_values: (Array[V] val | None) =
      // if we have only one result, pass it on up rather than
      // allocating another array
      if children.size() < 2 then
        try
          (let child_result_values: (Array[V] val | None), bindings') =
            children(0)?._values_aux(data, indent + 1, bindings')
          child_result_values
        end
      else
        recover val
          var result_values': (Array[V] | None) = None
          for child in children.values() do
            (let child_result_values: (Array[V] val | None), bindings') =
              child._values_aux(data, indent + 1, bindings')

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
      end

    // now run node's action, if any
    match node.action()
    | let action: Action[S, D, V] =>
      let result_values' =
        match result_values
        | let rv': Array[V] val =>
          rv'
        else
          recover val Array[V] end
        end
      (let value, bindings') = action(data, this, result_values', bindings')
      match value
      | let value': V =>
        result_values = recover val [ value' ] end
      else
        result_values = None
      end
    end

    // now bind variables
    match node
    | let bind: Bind[S, D, V] val =>
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
      | let rule: NamedRule[S, D, V] val =>
        s.append("Success(" + rule.name + "@[" + start.string() + "," +
          next.string() + "))")
      else
        s.append("Success(@[" + start.string() + "," + next.string() + "))")
      end
      s
    end
