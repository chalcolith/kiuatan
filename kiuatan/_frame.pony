
type _RuleFrame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share] is
  ( _BindFrame[S, D, V]
  | _CondFrame[S, D, V]
  | _ConjFrame[S, D, V]
  | _DisjFrame[S, D, V]
  | _ErrorFrame[S, D, V]
  | _LiteralFrame[S, D, V]
  | _LookFrame[S, D, V]
  | _NamedRuleFrame[S, D, V]
  | _NegFrame[S, D, V]
  | _SingleFrame[S, D, V]
  | _StarFrame[S, D, V] )

type _FrameResult[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is ( Result[S, D, V] | _RuleFrame[S, D, V] )

trait _Frame[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  fun ref run(child_result: (Result[S, D, V] | None)): _FrameResult[S, D, V]
