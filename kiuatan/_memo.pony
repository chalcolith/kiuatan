use "collections"

type _Memo[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  HashMap[_MemoKey[S, D, V], Result[S, D, V], _MemoHash[S, D, V]]

type _MemoKey[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  (NamedRule[S, D, V] box, Loc[S])

type _MemoLR[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  Map[Loc[S], _Involved[S, D, V]]

type _Involved[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  MapIs[NamedRule[S, D, V] box, _Expansions[S, D, V]]

type _Expansions[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  Array[Result[S, D, V]]

primitive _MemoHash[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  fun box hash(x: box->_MemoKey[S, D, V]!): USize =>
    (digestof x._1) xor x._2.hash()

  fun box eq(x: box->_MemoKey[S, D, V]!, y: box->_MemoKey[S, D, V]!): Bool =>
    (x._1 is y._1) and (x._2 == y._2)
