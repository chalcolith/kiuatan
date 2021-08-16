interface val ParseCallback[S, V: Any #share]
  """
  Used to report the results of a parse attempt.
  """
  fun apply(result: Result[S, V])
