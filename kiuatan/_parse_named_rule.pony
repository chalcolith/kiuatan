interface ref _ParseNamedRule[S, D: Any #share, V: Any #share]
  fun ref apply(
    depth: USize,
    rule: NamedRule[S, D, V] val,
    body: RuleNode[S, D, V] val,
    loc: Loc[S])
    : Result[S, D, V]
