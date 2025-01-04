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

  fun _values(data: D)
    : ReadSeq[V] val
  =>
    """
    Call the matched rules' actions to assemble a custom result value.
    """
    match _values_aux(data, 0)
    | (let result_values: Array[V] val, _) =>
      result_values
    else
      []
    end

  fun _values_aux(data: D, indent: USize)
    : ((Array[V] val | None), (Bindings[S, D, V] | None))
  =>
    // collect values from child results
    ( var result_values: (Array[V] trn | None)
    , var bindings: (Bindings[S, D, V] | None) ) =
      match children.size()
      | 0 =>
        (None, None)
      else
        // fold child results
        var result_values': (Array[V] trn | None) = None
        var bindings': (Bindings[S, D, V] | None) = None
        for child in children.values() do
          (let crv, let cb) = child._values_aux(data, indent + 1)

          match crv
          | let crv': Array[V] val if crv'.size() > 0 =>
            match result_values'
            | let rv: Array[V] trn =>
              rv.append(crv')
            else
              let rv: Array[V] trn = Array[V]
              rv.append(crv')
              result_values' = consume rv
            end
          end

          match cb
          | let child_bindings': Bindings[S, D, V] =>
            match bindings'
            | let parent_bindings: Bindings[S, D, V] =>
              // we want shallower bindings to override deeper ones
              // and later ones to override earlier ones
              for (v, child_binding) in child_bindings'.pairs() do
                match try parent_bindings(v)? end
                | let parent_binding: Binding[S, D, V] box =>
                  if child_binding.depth <= parent_binding.depth then
                    parent_bindings.update(v, child_binding)
                  end
                else
                  parent_bindings.update(v, child_binding)
                end
              end
            else
              bindings' = Bindings[S, D, V] .> concat(child_bindings'.pairs())
            end
          end
        end
        (consume result_values', bindings')
      end

    // run node's action
    var val_values: (Array[V] val | None) = consume result_values
    match node.action()
    | let action: Action[S, D, V] =>
      let val_values': Array[V] val =
        match val_values
        | let rv': Array[V] val =>
          consume rv'
        else
          []
        end
      let bindings' =
        match bindings
        | let bb': Bindings[S, D, V] =>
          bb'
        else
          Bindings[S, D, V]
        end
      let value = action(data, this, val_values', bindings')
      match value
      | let value': V =>
        val_values = [ value' ]
      else
        val_values = None
      end
    end

    // bind variable if necessary (even with empty values!)
    match node
    | let bind: Bind[S, D, V] box =>
      let bound_values: Array[V] val =
        match val_values
        | let val_values': Array[V] val =>
          val_values'
        else
          []
        end
      match bindings
      | let bindings': Bindings[S, D, V] =>
        bindings'.update(
          bind.variable, Binding[S, D, V](this, indent, bound_values))
      else
        bindings = Bindings[S, D, V] .> update(
          bind.variable, Binding[S, D, V](this, indent, bound_values))
      end
    end

    (val_values, bindings)

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
