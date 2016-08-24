
trait Loc[T]
  fun has_next(): Bool ?
  fun ref next(): box->T ?
  fun clone(): Loc[T]^


trait Segment[T]
  fun begin(): Loc[T]^ ?


class _SeqLoc[T] is Loc[T]
  let _seq: Seq[T] box
  var _i: USize

  new create(seq: Seq[T] box, i: USize) =>
    _seq = seq
    _i = i

  fun has_next(): Bool =>
    _i < _seq.size()

  fun ref next(): box->T ? =>
    if _i < _seq.size() then
      _seq(_i = _i + 1)
    else
      error
    end

  fun clone(): Loc[T]^ =>
    let loc = _SeqLoc[T](_seq, _i)
    consume loc


class _SeqSegment[T] is Segment[T]
  let _seq: Seq[T] box

  new create(seq: Seq[T] box) =>
    _seq = seq

  fun begin(): Loc[T]^ =>
    let loc = _SeqLoc[T](_seq, 0)
    consume loc


class _SegmentLoc[T] is Loc[T]
  let _segs: Array[Segment[T] box] box
  var _si: USize
  var _sl: (Loc[T] ref | None)

  new create(segs: Array[Segment[T] box] box) ? =>
    _segs = segs
    _si = 0
    _sl = if _si < _segs.size() then _segs(_si).begin() else None end

  new _create(segs: Array[Segment[T] box] box, si: USize, sl: (Loc[T] ref | None)) =>
    _segs = segs
    _si = si
    _sl = sl

  fun has_next(): Bool ? =>
    match _sl
    | let loc: this->Loc[T] ref =>
      if loc.has_next() then
        true
      elseif _si < (_segs.size() - 1) then
        let ni = _si + 1
        let nl = _segs(ni).begin()
        nl.has_next()
      else
        false
      end
    else
      false
    end

  fun ref next(): box->T ? =>
    match _sl
    | let loc: Loc[T] =>
      if loc.has_next() then
        loc.next()
      elseif _si < (_segs.size() - 1) then
        let ni = _si + 1
        let nl = _segs(ni).begin()
        if nl.has_next() then
          _si = ni
          _sl = nl
          nl.next()
        else
          error
        end
      else
        _sl = None
        error
      end
    else
      error
    end

  fun clone(): Loc[T]^ =>
    let sl = match _sl
    | let loc: this->Loc[T] => loc.clone()
    else None end

    let loc = _SegmentLoc[T]._create(_segs, _si, sl)
    consume loc


class Source[T] is Segment[T]
  let _segs: Array[Segment[T] box] box

  new create(seqs: this->Seq[Seq[T]]) =>
    var segs = Array[Segment[T] box](seqs.size())
    for s in seqs.values() do
      let seg = _SeqSegment[T](s)
      segs.push(seg)
    end
    _segs = segs

  fun box begin(): Loc[T]^ ? =>
    _SegmentLoc[T](_segs)
