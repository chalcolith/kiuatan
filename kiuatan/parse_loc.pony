use "collections"

type ParseSegment[T] is ListNode[ReadSeq[T] box]
  """
  Kiuatan parsers match over linked lists of sequences of items of type `T`.
  """

class ParseLoc[T] is (Comparable[ParseLoc[T]] & Hashable & Stringable)
  """
  A pointer to a particular location in a linked list of sequences of items
  of type `T`.
  """

  var _segment: ParseSegment[T] box
  var _index: USize

  new create(segment': ParseSegment[T] box, index': USize = 0) =>
    """
    Create a pointer to an item at `index'` in a linked list node  `segment'`.
    """
    _segment = segment'
    _index = index'

  fun segment(): ParseSegment[T] box =>
    """
    The segment (linked list node) to whose sequence this points to.
    """
    _segment

  fun index() =>
    """
    The index of the item this location points to.
    """
    _index

  fun ref has_next(): Bool =>
    """
    Returns `true` if there is an item after this one, i.e. if there is
    a next item in this segment's sequence, or if there is a next segment
    with at least one item in its sequence.
    """
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
    """
    Returns the item this location points to, and increments the location.
    """
    var seq = _segment()?
    if _index >= seq.size() then
      _segment = _segment.next() as ParseSegment[T] box
      _index = 0
      seq = _segment()?
    end
    seq(_index = _index + 1)?

  fun clone(): ParseLoc[T]^ =>
    """
    Creates a clone of this location pointing to the same index in the same
    segment.
    """
    ParseLoc[T](_segment, _index)

  fun values(next': ParseLoc[T] box): ParseLocIterator[T]^ =>
    """
    Returns an interator that starts at this location's next item, and
    returns items up to but not including the `next` location's.
    """
    ParseLocIterator[T](this, next')

  fun add(n: USize): ParseLoc[T]^ ? =>
    """
    Returns a new location that points `n` items past this one.
    """
    let cur = clone()
    var i: USize = 0
    while i < n do
      cur.next()?
      i = i + 1
    end
    consume cur

  fun eq(that: box->ParseLoc[T]) : Bool =>
    """
    Returns `true` if `that`'s segment and index are identical to this one's.
    """
    (_segment is that._segment) and (_index == that._index)

  fun ne(that: box->ParseLoc[T]) : Bool =>
    """
    Returns `true` if `that`'s segment or index are different from this one's.
    """
    not ((_segment is that._segment) and (_index == that._index))

  fun lt(that: box->ParseLoc[T]) : Bool =>
    """
    Returns `true` if this location's segment precedes `that`'s in the linked
    list, or if they have the same segment but this one's index is less than
    `that`'s.
    """
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
    """
    Returns `true` if this location's segment precedes `that`'s in the linked
    list, or if they have the same segment but this one's index is less than
    or equal to `that`'s.
    """
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
    """
    Returns `true` if this location's segment succeeds `that`'s in the linked
    list, or if they have the same segment but this one's index is greater than
    or equal to `that`'s.
    """
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
    """
    Returns `true` if this location's segment succeeds `that`'s in the linked
    list, or if they have the same segment but this one's index is greater than
    `that`'s.
    """
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
    """
    Returns a hash value for this location.
    """
    HashIs[ParseSegment[T]].hash(_segment) xor U64.from[USize](_index)

  fun string(): String iso^ =>
    """
    Returns a string representation of this location (the index of the segment
    and the index in the segment).
    """
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
  """
  An iterator for parse locations.
  """
  let _start: ParseLoc[T] box
  let _next: ParseLoc[T] box
  var _cur: ParseLoc[T] ref

  new create(start': ParseLoc[T] box, next': ParseLoc[T] box) =>
    """
    Creates an iterator that begins with `start'`'s item and continues
    up to but not including `next'`'s item.
    """
    _start = start'.clone()
    _next = next'.clone()
    _cur = _start.clone()

  fun ref reset() =>
    """
    Resets the iterator to its starting location.
    """
    _cur = _start.clone()

  fun ref has_next(): Bool =>
    """
    Returns `true` if the iterator has a next item.
    """
    _cur.has_next() and (_cur != _next)

  fun ref next(): box->T ? =>
    """
    Returns the iterator's next item and increments the iterator.
    """
    _cur.next()?
