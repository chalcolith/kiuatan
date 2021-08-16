interface val Action[S, V: Any #share]
  """
  Used to assemble a custom result value.
  """
  fun apply(result: Success[S, V], child_values: Array[(V | None)],
    bindings: Bindings[S, V]): ((V | None), Bindings[S, V])
