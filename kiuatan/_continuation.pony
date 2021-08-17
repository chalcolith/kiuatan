use per = "collections/persistent"

interface val _Continuation[S, D: Any #share, V: Any #share]
  fun apply(result: Result[S, D, V], stack: _LRStack[S, D, V],
    recursions: _LRByRule[S, D, V])
