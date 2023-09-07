use per = "collections/persistent"

class val Variable
  let name: String

  new val create(name': String) =>
    name = name'

type Binding[S, D: Any #share, V: Any #share] is
  (Success[S, D, V], ReadSeq[V] val)

class val Bindings[S, D: Any #share, V: Any #share]
  let _bindings: per.MapIs[Variable, per.List[Binding[S, D, V]]]

  new val create() =>
    _bindings = per.MapIs[Variable, per.List[Binding[S, D, V]]]

  new val _prepend(
    prev: Bindings[S, D, V],
    variable: Variable,
    binding: Binding[S, D, V])
  =>
    let list =
      try
        prev._bindings(variable)?.prepend(binding)
      else
        per.Cons[Binding[S, D, V]](binding, per.Nil[Binding[S, D, V]])
      end
    _bindings = prev._bindings.update(variable, list)

  fun val add(variable: Variable, binding: Binding[S, D, V])
    : Bindings[S, D, V]
  =>
    Bindings[S, D, V]._prepend(this, variable, binding)

  fun val result(variable: Variable, enclosing_success: Success[S, D, V])
    : Success[S, D, V] ?
  =>
    this(variable, enclosing_success)?._1

  fun val values(variable: Variable, enclosing_success: Success[S, D, V])
    : ReadSeq[V] val ?
  =>
    this(variable, enclosing_success)?._2

  fun val apply(variable: Variable, enclosing_success: Success[S, D, V])
    : Binding[S, D, V] ?
  =>
    // get the list of bindings in top-down order
    let var_bindings = _bindings(variable)?

    // now starting from our enclosing result, do a breadth-first search
    // of results until we find the first matching binding
    // we do children in reverse order so we find the last binding in a conj
    let queue = [ enclosing_success ]
    while queue.size() > 0 do
      let success = queue.shift()?
      for (bs, vs) in var_bindings.values() do
        if bs == success then
          return (bs, vs)
        end
      end
      var i = success.children.size()
      while i > 0 do
        queue.push(success.children(i-1)?)
        i = i - 1
      end
    end
    error

  fun val contains(variable: (Variable | None)): Bool =>
    match variable
    | let variable': Variable =>
      _bindings.contains(variable')
    else
      false
    end
