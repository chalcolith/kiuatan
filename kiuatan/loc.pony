
use col = "collections"
use per = "collections/persistent"

type Segment[T] is ReadSeq[T] val
type Source[T] is per.List[Segment[T]]

class val Loc[T]
  is (col.Hashable & Equatable[Loc[T]] & Comparable[Loc[T]] & Stringable)
  """
  Represents a location in a [`Source`](/kiuatan-Source) at which to parse, or at which a parse has matched.
  """

  let _segment: per.List[Segment[T]]
  let _index: USize

  new val create(segment: per.List[Segment[T]], index: USize = 0) =>
    """
    Create a new location in the given segment.
    """
    _segment = segment
    _index = index

  fun has_value(): Bool =>
    """
    Returns `true` if there is actually an item at the location, i.e. if the location points to a valid place in the segment.
    """
    try
      _index < _segment(0)?.size()
    else
      false
    end

  fun apply(): val->T ? =>
    """
    Returns the item at the location.
    """
    _segment(0)?(_index)?

  fun next(): Loc[T] =>
    """
    Returns the next location in the source.  May not be valid.
    """
    try
      if (_index+1) >= _segment(0)?.size() then
        match _segment.tail()?
        | let cons: per.Cons[Segment[T]] =>
          return Loc[T](cons, 0)
        end
      end
    end
    Loc[T](_segment, _index + 1)

  fun add(n: USize): Loc[T] =>
    """
    Returns a location `n` places further in the source.  May not be valid.
    """
    var cur = Loc[T](_segment, _index)
    var i = n
    while i > 0 do
      cur = cur.next()
      i = i - 1
    end
    cur

  fun values(nxt: (Loc[T] | None) = None): Iterator[val->T] =>
    let self = this
    match nxt
    | let nxt': Loc[T] =>
      object
        var cur: Loc[T] box = self

        fun ref has_next(): Bool =>
          cur.has_value() and not (cur == nxt')

        fun ref next(): val->T ? =>
          if cur.has_value() then
            (cur = cur.next())()?
          else
            error
          end
      end
    else
      object
        var cur: Loc[T] box = self

        fun ref has_next(): Bool =>
          cur.has_value()

        fun ref next(): val->T ? =>
          if cur.has_value() then
            (cur = cur.next())()?
          else
            error
          end
      end
    end

  fun eq(that: Loc[T] box): Bool =>
    """
    Returns `true` if the two locations point to the same spot in the same segment.
    """
    try
      (_index == that._index) and (_segment(0)? is that._segment(0)?)
    else
      false
    end

  fun ne(that: Loc[T] box): Bool =>
    """
    Returns `true` if the two locations do not point to the same spot in the same segment.
    """
    try
      not ((_index == that._index) and (_segment(0)? is that._segment(0)?))
    else
      false
    end

  fun gt(that: Loc[T] box): Bool =>
    """
    Returns `true` if `this` is further along in the source than `that`.  Should be used sparingly, as it has to count up from `this`, possibly to the end of the source.
    """
    if this._segment is that._segment then
      this._index > that._index
    else
      var cur = that.next()
      while cur.has_value() do
        if cur == this then
          return true
        end
        cur = cur.next()
      end
      false
    end

  fun ge(that: Loc[T] box): Bool =>
    (this == that) or (this > that)

  fun lt(that: Loc[T] box): Bool =>
    """
    Returns `true` if `that` is further along in the source than `this`.  Should be used sparingly, as it has to count up from `that`, possibly to the end of the source.
    """
    if this._segment is that._segment then
      this._index < that._index
    else
      var cur = this.next()
      while cur.has_value() do
        if cur == that then
          return true
        end
        cur = cur.next()
      end
      false
    end

  fun le(that: Loc[T] box): Bool =>
    (this == that) or (this < that)

  fun hash(): USize =>
    try
      let seq = _segment(0)?
      (digestof seq) xor _index
    else
      0
    end

  fun string(): String iso^ =>
    recover
      let s = String
      // try
      //   let seq = _segment(0)?
      //   s.append((digestof seq).string())
      //   s.append(":")
      // end
      s.append(_index.string())
      s
    end
