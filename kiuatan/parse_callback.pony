interface val ParseCallback[S, D: Any #share, V: Any #share]
  """
  Used to report the results of a parse attempt.
  """
  fun apply(result: Result[S, D, V], values: ReadSeq[V] val)
