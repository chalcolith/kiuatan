use "collections"

class val Variable
  let name: String

  new val create(name': String) =>
    name = name'

type Binding[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  (Success[S, D, V], ReadSeq[V])

class box Bindings[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  let _bindings: MapIs[Variable, Array[Binding[S, D, V]]]

  new create() =>
    _bindings = _bindings.create()

  fun ref add(variable: Variable, binding: Binding[S, D, V]) =>
    let list: Array[Binding[S, D, V]] =
      match try _bindings(variable)? end
      | let arr: Array[Binding[S, D, V]] =>
        arr
      else
        let arr = Array[Binding[S, D, V]]
        _bindings(variable) = arr
        arr
      end
    list.push(binding)

  fun result(variable: Variable, enclosing_success: Success[S, D, V])
    : Success[S, D, V] ?
  =>
    this(variable, enclosing_success)?._1

  fun values(variable: Variable, enclosing_success: Success[S, D, V])
    : ReadSeq[V] box ?
  =>
    this(variable, enclosing_success)?._2

  fun apply(variable: Variable, enclosing_success: Success[S, D, V])
    : Binding[S, D, V] ?
  =>
    // get the list of bindings in top-down order
    let var_bindings = _bindings(variable)?

    // now starting from our enclosing result, do a breadth-first search
    // of results until we find the first matching binding
    // we do children in reverse order so we find the last binding in a conj
    let queue: Array[Success[S, D, V]] = [ enclosing_success ]
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

  fun contains(
    variable: (Variable | None),
    enclosing_success: Success[S, D, V])
    : Bool
  =>
    match variable
    | let variable': Variable =>
      try
        apply(variable', enclosing_success)?
        return true
      end
    end
    false
