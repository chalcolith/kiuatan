type _SegmentUpdate[S] is (_InsertSeg[S] | _RemoveSeg)

class val _InsertSeg[S]
  let index: USize
  let segment: Segment[S]

  new val create(index': USize, segment': Segment[S]) =>
    index = index'
    segment = segment'

class val _RemoveSeg
  let index: USize

  new val create(index': USize) =>
    index = index'
