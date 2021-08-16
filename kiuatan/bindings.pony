use per = "collections/persistent"

class tag Variable

type Bindings[S, V: Any #share] is per.MapIs[Variable, (Success[S, V], (V | None))]
