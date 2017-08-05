use "collections"

type ParseSegment[T] is ListNode[ReadSeq[T] box]

class ParseLoc[T] is (Comparable[ParseLoc[T]] & Hashable & Stringable)
  """
  A pointer to a particular location in list of source sequences.
  """

  var _segment: ParseSegment[T] box
  var _index: USize

  new create(segment': ParseSegment[T] box, index': USize = 0) =>
    _segment = segment'
    _index = index'

  fun segment(): ParseSegment[T] box =>
    _segment

  fun index() =>
    _index

  fun ref has_next(): Bool =>
    try
      if _index < _segment()?.size() then
        return true
      elseif _segment.has_next() then
        let n = _segment.next() as ParseSegment[T] box
        return n()?.size() > 0
      end
    end
    false

  fun ref next(): box->T ? =>
    var seq = _segment()?
    if _index >= seq.size() then
      _segment = _segment.next() as ParseSegment[T] box
      _index = 0
      seq = _segment()?
    end
    seq(_index = _index + 1)?

  fun clone(): ParseLoc[T]^ =>
    ParseLoc[T](_segment, _index)

  fun values(next': ParseLoc[T] box): ParseLocIterator[T]^ =>
    ParseLocIterator[T](this, next')

  fun add(n: USize): ParseLoc[T]^ ? =>
    let cur = clone()
    var i: USize = 0
    while i < n do
      cur.next()?
      i = i + 1
    end
    consume cur

  fun eq(that: box->ParseLoc[T]) : Bool =>
    (_segment is that._segment) and (_index == that._index)

  fun ne(that: box->ParseLoc[T]) : Bool =>
    not ((_segment is that._segment) and (_index == that._index))

  fun lt(that: box->ParseLoc[T]) : Bool =>
    if _segment is that._segment then
      _index < that._index
    else
      var cur = recover val this._segment end
      while not (cur is that._segment) do
        if not cur.has_next() then return false end
        match cur.next()
        | let n: ListNode[ReadSeq[T] box] val => cur = n
        else return false end
      end
      true
    end

  fun le(that: box->ParseLoc[T]) : Bool =>
    if _segment is that._segment then
      _index <= that._index
    else
      var cur = recover val this._segment end
      while not (cur is that._segment) do
        if not cur.has_next() then return false end
        match cur.next()
        | let n: ListNode[ReadSeq[T] box] val => cur = n
        else return false end
      end
      true
    end

  fun ge(that: box->ParseLoc[T]) : Bool =>
    if _segment is that._segment then
      _index >= that._index
    else
      var cur = recover val this._segment end
      while not (cur is that._segment) do
        if not cur.has_prev() then return false end
        match cur.prev()
        | let n: ListNode[ReadSeq[T] box] val => cur = n
        else return false end
      end
      true
    end

  fun gt(that: box->ParseLoc[T]): Bool =>
    if _segment is that._segment then
      _index > that._index
    else
      var cur = recover this._segment end
      while not (cur is that._segment) do
        if not cur.has_prev() then return false end
        match cur.prev()
        | let n: ListNode[ReadSeq[T] box] val => cur = n
        else return false end
      end
      true
    end

  fun hash() : U64 val =>
    HashIs[ParseSegment[T]].hash(_segment) xor U64.from[USize](_index)

  fun string(): String iso^ =>
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


class ParseLocIterator[T]
  let _start: ParseLoc[T] box
  let _next: ParseLoc[T] box
  var _cur: ParseLoc[T] ref

  new create(start': ParseLoc[T] box, next': ParseLoc[T] box) =>
    _start = start'.clone()
    _next = next'.clone()
    _cur = _start.clone()

  fun ref reset() =>
    _cur = _start.clone()

  fun ref has_next(): Bool =>
    _cur.has_next() and (_cur != _next)

  fun ref next(): box->T ? =>
    _cur.next()?
