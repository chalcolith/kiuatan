interface val _Continuation[S, D: Any #share, V: Any #share]
  fun apply(state: _ParseState[S, D, V], result: Result[S, D, V])
