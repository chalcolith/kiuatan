
trait Loc[T]
  """
  A pointer to a particular location in a Source.
  """
  fun has_next(): Bool ?
  fun ref next(): box->T ?

  fun eq(other: box->Loc[T]): Bool
  fun ne(other: box->Loc[T]): Bool
  fun lt(other: box->Loc[T]): Bool
  fun le(other: box->Loc[T]): Bool
  fun ge(other: box->Loc[T]): Bool
  fun gt(other: box->Loc[T]): Bool

  fun clone(): Loc[T]^


trait Segment[T]
  """
  Contains a part of a Source.
  """
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

  fun eq(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i == other'._i)
    end
    false

  fun ne(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (not (_seq is other'._seq)) or (_i != other'._i)
    end
    false

  fun lt(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i < other'._i)
    end
    false

  fun le(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i <= other'._i)
    end
    false

  fun ge(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i >= other'._i)
    end
    false

  fun gt(other: box->Loc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i > other'._i)
    end
    false

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


class MatchSourceLoc[T] is Loc[T]
  let _segs: Array[Segment[T] box] box
  var _si: USize
  var _sl: (Loc[T] ref | None)

  new create(segs: Array[Segment[T] box] box) ? =>
    _segs = segs
    _si = 0
    _sl = if _si < _segs.size() then _segs(_si).begin() else None end

  new begin_segment(segs: Array[Segment[T] box] box, si: USize) ? =>
    _segs = segs
    _si = si
    _sl = if _si < _segs.size() then
      _segs(_si).begin()
    else
      None
    end

  new _from_orig(segs: Array[Segment[T] box] box, si: USize, sl: (Loc[T] ref | None)) =>
    _segs = segs
    _si = si
    _sl = sl

  fun segments(): Array[Segment[T] box] box => _segs

  fun index(): USize => _si

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
        return loc.next()
      elseif _si < (_segs.size() - 1) then
        _si = _si + 1
        let nl = _segs(_si).begin()
        if nl.has_next() then
          _sl = nl
          return nl.next()
        else
          _sl = None
        end
      end
    end
    _sl = None
    error

  fun eq(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      match _sl
      | let la: Loc[T] box =>
        match other'._sl
        | let lb: box->Loc[T] =>
          res = la == lb
        end
      end
    end
    res

  fun ne(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      match _sl
      | let la: Loc[T] box =>
        match other'._sl
        | let lb: box->Loc[T] =>
          res = la != lb
        end
      else
        res = not (other'._sl is None)
      end
    end
    res

  fun lt(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      if _si < other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: Loc[T] box =>
          match other'._sl
          | let lb: box->Loc[T] =>
            res = la < lb
          end
        end
      end
    end
    res

  fun le(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      if _si < other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: Loc[T] box =>
          match other'._sl
          | let lb: box->Loc[T] =>
            res = la <= lb
          end
        end
      end
    end
    res

  fun ge(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      if _si > other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: Loc[T] box =>
          match other'._sl
          | let lb: box->Loc[T] =>
            res = la >= lb
          end
        end
      end
    end
    res

  fun gt(other: box->Loc[T]): Bool =>
    var res = false
    try
      let other' = other as box->MatchSourceLoc[T]
      if _si > other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: Loc[T] box =>
          match other'._sl
          | let lb: box->Loc[T] =>
            res = la > lb
          end
        end
      end
    end
    res

  fun clone(): Loc[T]^ =>
    let sl =
      match _sl
      | let loc: this->Loc[T] => loc.clone()
      else None end

    let loc = MatchSourceLoc[T]._from_orig(_segs, _si, sl)
    consume loc


class MatchSource[T] is Segment[T]
  let _segs: Array[Segment[T] box] ref

  new create(seqs: this->Seq[Seq[T]]) =>
    var segs = Array[Segment[T] box](seqs.size())
    for s in seqs.values() do
      let seg = _SeqSegment[T](s)
      segs.push(seg)
    end
    _segs = segs

  fun begin(): Loc[T]^ ? =>
    let loc = MatchSourceLoc[T](_segs)
    consume loc

  fun begin_segment(i: USize): MatchSourceLoc[T]^ ? =>
    let loc = MatchSourceLoc[T].begin_segment(_segs, i)
    consume loc

  fun ref segments(): Array[Segment[T] box] ref =>
    _segs
