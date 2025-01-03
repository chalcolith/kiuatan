type Result[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  is (Success[S, D, V] | Failure[S, D, V])
  """
  The result of a parse attempt, either successful or failed.
  """

class box Success[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  """
  The result of a successful parse.
  """

  let node: RuleNode[S, D, V]
  """The rule that matched successfully."""

  let start: Loc[S]
  """The location at which the rule matched."""

  let next: Loc[S]
  """The location one past the end of the match."""

  let children: ReadSeq[Success[S, D, V]]
  """Results from child rules' matches."""

  new create(
    node': RuleNode[S, D, V],
    start': Loc[S],
    next': Loc[S],
    children': ReadSeq[Success[S, D, V]] box = [])
  =>
    node = node'
    start = start'
    next = next'
    children = children'

  fun _values(data: D, bindings: Bindings[S, D, V] ref = Bindings[S, D, V])
    : ReadSeq[V]
  =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    match _values_aux(data, 0, bindings)
    | let result_values: Array[V] =>
      result_values
    else
      []
    end

  fun _values_aux(data: D, indent: USize, bindings: Bindings[S, D, V] ref)
    : (Array[V] | None)
  =>
    // collect values from child results
    var result_values: (Array[V] | None) =
      // if we have only one result, pass it on up rather than
      // allocating another array
      match children.size()
      | 0 =>
        None
      | 1 =>
        try
          children(0)?._values_aux(data, indent + 1, bindings)
        end
      else
        // fold child results
        var result_values': (Array[V] | None) = None
        for child in children.values() do
          match child._values_aux(data, indent + 1, bindings)
          | let crv: Array[V] if crv.size() > 0 =>
            result_values' =
              match result_values'
              | let rv: Array[V] =>
                rv .> append(crv)
              else
                crv
              end
          end
        end
        result_values'
      end

    // now run node's action, if any
    match node.action()
    | let action: Action[S, D, V] =>
      let result_values': Array[V] =
        match result_values
        | let rv': Array[V] =>
          rv'
        else
          []
        end
      let value = action(data, this, result_values', bindings)
      match value
      | let value': V =>
        result_values = [ value' ]
      else
        result_values = None
      end
    end

    // now bind variables
    match node
    | let bind: Bind[S, D, V] box =>
      let result_values' =
        match result_values
        | let rv': Array[V] =>
          rv'
        else
          recover val Array[V] end
        end
      bindings.add(bind.variable, (this, result_values'))
    end
    result_values

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
    match node
    | let rule: NamedRule[S, D, V] box =>
      "Success(" + rule.name + "@[" + start.string() + "," + next.string() +
        "))"
    else
      "Success(@[" + start.string() + "," + next.string() + "))"
    end
