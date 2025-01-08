interface val Action[
  S: (Any #read & Equatable[S]),
  D: Any #share,
  V: Any #share]
  """
  Used to assemble a custom result value.
  """
  fun apply(
    data: D,
    result: Success[S, D, V],
    child_values: ReadSeq[V] val,
    bindings: Bindings[S, D, V])
    : (V | None)
