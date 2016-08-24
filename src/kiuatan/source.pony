

trait Loc[T: Any #read, S: Seq[T] box]
  fun ref has_next(): Bool val ?
  fun ref next(): S->T ?
  fun clone(): Loc[T,S] ref ?

trait Segment[T: Any #read, S: Seq[T] box]
  fun begin(): Loc[T,S] ref ?


class _SeqLoc[T: Any #read, S: Seq[T] box] is Loc[T,S]
  let _s: S
  var _i: USize

  new create(s: S, i: USize) =>
    _s = s
    _i = i

  fun box has_next(): Bool val =>
    _i < _s.size()

  fun ref next(): S->T ? =>
    if _i < _s.size() then
      _s(_i = _i + 1)
    else
      error
    end

  fun clone(): Loc[T,S] ref =>
    _SeqLoc[T,S](_s, _i)


class box _SeqSegment[T: Any #read, S: Seq[T] box] is Segment[T,S]
  let _s: S

  new box create(s: S) ? =>
    if s.size() == 0 then error end
    _s = s

  fun box begin(): Loc[T,S] =>
    _SeqLoc[T,S](_s, 0)


class _SourceLoc[T: Any #read, S: Seq[T] box] is Loc[T,S]
  let _segs: Seq[Segment[T,S] box] box
  var _si: USize
  var _loc: Loc[T,S]

  new create(segs: Seq[Segment[T,S] box] box, si: USize) ? =>
    if segs.size() == 0 then error end
    _segs = segs
    _si = si
    _loc = segs(_si).begin()

  fun ref has_next(): Bool val ? =>
    if _loc.has_next() then
      true
    elseif _si < (_segs.size() - 1) then
      _si = _si + 1
      try _loc = _segs(_si).begin() end
      _loc.has_next()
    else
      false
    end

  fun ref next(): S->T ? =>
    if has_next() then
      _loc.next()
    else
      error
    end

  fun clone(): Loc[T,S] ref ? =>
    _SourceLoc[T,S](_segs, _si)


class box Source[T: Any #read, S: Seq[T] box] is Segment[T,S]
  let _segments: Array[Segment[T,S] box]

  new box create(seqs: Seq[S] box) ? =>
    if seqs.size() == 0 then error end

    _segments = Array[Segment[T,S] box]()
    for s in seqs.values() do
      let seg = _SeqSegment[T,S](s)
      _segments.push(seg)
    end

  fun box begin(): Loc[T,S] ? =>
    _SourceLoc[T,S](_segments, 0)
