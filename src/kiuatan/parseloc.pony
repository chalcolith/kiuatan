use "collections"

type ParseSegment[T] is ListNode[ReadSeq[T]]

class ParseLoc[T] is (Equatable[ParseLoc[T]] & Hashable & Stringable)
  """
  A pointer to a particular location in list of source sequences.
  """

  var _segment: ParseSegment[T] box
  var _index: USize

  new create(node': ParseSegment[T] box, index': USize = 0) =>
    _segment = node'
    _index = index'

  fun box segment(): box->ParseSegment[T] =>
    _segment

  fun box index() =>
    _index

  fun has_next(): Bool =>
    try
      if _index < _segment().size() then
        return true
      elseif _segment.has_next() then
        let n = _segment.next() as ParseSegment[T] box
        return n().size() > 0
      end
    end
    false

  fun ref next(): box->T ? =>
    var seq = _segment()
    if _index >= seq.size() then
      _segment = _segment.next() as ParseSegment[T] box
      _index = 0
      seq = _segment()
    end
    seq(_index = _index + 1)

  fun box clone(): ParseLoc[T]^ =>
    ParseLoc[T](_segment, _index)

  fun box add(n: USize): ParseLoc[T]^ ? =>
    let cur = clone()
    var i: USize = 0
    while i < n do
      cur.next()
      i = i + 1
    end
    consume cur

  fun box eq(that: box->ParseLoc[T]) : Bool =>
    (_segment is that._segment) and (_index == that._index)

  fun box ne(that: box->ParseLoc[T]) : Bool =>
    not ((_segment is that._segment) and (_index == that._index))

  fun box hash() : U64 val =>
    HashIs[ParseSegment[T]].hash(_segment) xor U64.from[USize](_index)

  fun box string(): String iso^ =>
    var num: USize = 0
    try
      var cur: ParseSegment[T] box = _segment
      while cur.has_prev() do
        num = num + 1
        cur = cur.prev() as ParseSegment[T] box
      end
    end
    var s = recover String end
    s.append(num.string())
    s.append(":")
    s.append(_index.string())
    consume s
