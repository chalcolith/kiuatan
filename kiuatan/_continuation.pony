use per = "collections/persistent"

interface val _Continuation[S, V: Any #share]
  fun apply(result: Result[S, V], stack: per.List[_LRRecord[S, V]],
    recur: _LRByRule[S, V])
