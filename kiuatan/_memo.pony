use "collections"

type _Memo[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  MapIs[NamedRule[S, D, V] tag, _MemoByLoc[S, D, V]]

type _MemoByLoc[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  Map[Loc[S], Result[S, D, V]]
