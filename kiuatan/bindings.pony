use "collections"

class val Variable
  let name: String

  new val create(name': String) =>
    name = name'

class Binding[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  let success: Success[S, D, V]
  let depth: USize
  let values: ReadSeq[V] val

  new create(
    success': Success[S, D, V],
    depth': USize,
    values': ReadSeq[V] val)
  =>
    success = success'
    depth = depth'
    values = values'

type Bindings[S: (Any #read & Equatable[S]), D: Any #share, V: Any #share]
  is MapIs[Variable, Binding[S, D, V] box]
