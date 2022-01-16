use per = "collections/persistent"

class tag Variable

type Bindings[S, D: Any #share, V: Any #share] is
  per.MapIs[Variable, (Success[S, D, V], ReadSeq[V] val)]
