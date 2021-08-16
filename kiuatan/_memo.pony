use col = "collections"

type _Memo[S, V: Any #share] is
  col.MapIs[Rule[S, V] tag, _MemoByLoc[S, V]]

type _MemoByLoc[S, V: Any #share] is
  col.Map[Loc[S], _MemoByExpansion[S, V]]

type _MemoByExpansion[S, V: Any #share] is
  Array[(Result[S, V] | None)]
