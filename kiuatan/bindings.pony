use per = "collections/persistent"

class val Variable
  let name: String

  new val create(name': String) =>
    name = name'

type Bindings[S, D: Any #share, V: Any #share] is
  per.MapIs[Variable, (Success[S, D, V], ReadSeq[V] val)]
