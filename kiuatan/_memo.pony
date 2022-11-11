use "collections"

type _Memo[S, D: Any #share, V: Any #share] is
  MapIs[NamedRule[S, D, V] tag, _MemoByLoc[S, D, V]]

type _MemoByLoc[S, D: Any #share, V: Any #share] is
  Map[Loc[S], Result[S, D, V]]
