use "itertools"


trait Loc[T]
  fun ref has_next(): Bool
  fun ref next(): T ?
  fun clone(): Loc[T] ref ?


trait Segment[T]
  fun begin(): Loc[T] ref ?


class _SeqLoc[T: Any val] is Loc[T]
  let _a: Seq[T] val
  var _i: USize

  new create(a: Seq[T] val, i: USize) =>
    _a = a
    _i = i

  fun ref has_next(): Bool =>
    _i < _a.size()

  fun ref next(): T ? =>
    if _i < _a.size() then
      _a(_i = _i + 1)
    else
      error
    end

  fun clone(): Loc[T] ref =>
    _SeqLoc[T](_a, _i)


class val _SeqSegment[T: Any val] is Segment[T]
  let _a: Seq[T] val

  new create(a: Seq[T] val) ? =>
    if a.size() == 0 then error end
    _a = a

  fun begin(): Loc[T] ref =>
    _SeqLoc[T](_a, 0)


class _SourceLoc[T: Any val] is Loc[T]
  let _segs: Seq[Segment[T] val] val
  var _si: USize
  var _loc: Loc[T]

  new create(segs: Seq[Segment[T] val] val, si: USize) ? =>
    if segs.size() == 0 then error end
    _segs = segs
    _si = si
    _loc = segs(_si).begin()

  fun ref has_next(): Bool =>
    if _loc.has_next() then
      true
    elseif _si < (_segs.size() - 1) then
      _si = _si + 1
      try _loc = _segs(_si).begin() end
      _loc.has_next()
    else
      false
    end

  fun ref next(): T ? =>
    if has_next() then
      _loc.next()
    else
      error
    end

  fun clone(): Loc[T] ref ? =>
    _SourceLoc[T](_segs, _si)


class Source[T: Any val] is Segment[T]
  let _segments: Seq[Segment[T] val] val

  new from_seqs(seqs: Seq[Seq[T] val] val) ? =>
    if seqs.size() == 0 then error end

    var segs = Array[Segment[T] val]()
    for s in seqs.values() do
      let seg = _SeqSegment[T](s)
      segs.push(seg)
    end

  fun begin(): Loc[T] ref ? =>
    _SourceLoc[T](_segments, 0)
