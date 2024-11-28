interface val _Continuation[S, D: Any #share, V: Any #share]
  fun apply(result: Result[S, D, V])
