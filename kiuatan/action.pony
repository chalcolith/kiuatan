interface val Action[S, D: Any #share, V: Any #share]
  """
  Used to assemble a custom result value.
  """
  fun apply(result: Success[S, D, V], child_values: Array[(V | None)], data: D,
    bindings: Bindings[S, D, V]): ((V | None), Bindings[S, D, V])
