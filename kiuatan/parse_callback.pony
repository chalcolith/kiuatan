interface val ParseCallback[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  """
  Used to report the results of a parse attempt.
  """
  fun apply(result: Result[S, D, V], values: ReadSeq[V])
