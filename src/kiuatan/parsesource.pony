use "collections"

trait ParseLoc[T] is (Comparable[ParseLoc[T]] & Stringable)
  """
  A pointer to a particular location in a Source.
  """

  fun box has_next(): Bool ?
  fun ref next(): box->T ?

  fun box add(n: USize): ParseLoc[T]^ ? =>
    let cur = clone()
    for i in Range(0, n) do
      cur.next()
    end
    cur

  fun clone(): ParseLoc[T]^


trait _ParseSegment[T]
  """
  Contains a part of a Source.
  """
  fun box begin(): ParseLoc[T]^ ?


class _SeqLoc[T] is ParseLoc[T]
  let _seq: ReadSeq[T] box
  var _i: USize

  new create(seq: ReadSeq[T] box, i: USize) =>
    _seq = seq
    _i = i

  fun box has_next(): Bool =>
    _i < _seq.size()

  fun ref next(): box->T ? =>
    if _i < _seq.size() then
      _seq(_i = _i + 1)
    else
      error
    end

  fun box eq(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i == other'._i)
    end
    false

  fun box ne(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (not (_seq is other'._seq)) or (_i != other'._i)
    end
    false

  fun box lt(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i < other'._i)
    end
    false

  fun box le(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i <= other'._i)
    end
    false

  fun box ge(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i >= other'._i)
    end
    false

  fun box gt(other: box->ParseLoc[T]): Bool =>
    try
      let other' = other as box->_SeqLoc[T]
      (_seq is other'._seq) and (_i > other'._i)
    end
    false

  fun box clone(): ParseLoc[T]^ =>
    let loc = _SeqLoc[T](_seq, _i)
    consume loc

  fun box string(): String iso^ =>
    _i.string()


class _SeqSegment[T] is _ParseSegment[T]
  let _seq: Seq[T] box

  new create(seq: Seq[T] box) =>
    _seq = seq

  fun box begin(): ParseLoc[T]^ =>
    let loc = _SeqLoc[T](_seq, 0)
    consume loc


class _ParseSourceLoc[T] is ParseLoc[T]
  let _segs: Array[_ParseSegment[T] box] box
  var _si: USize
  var _sl: (ParseLoc[T] ref | None)

  new create(segs: Array[_ParseSegment[T] box] box) ? =>
    _segs = segs
    _si = 0
    _sl = if _si < _segs.size() then _segs(_si).begin() else None end

  new begin_segment(segs: Array[_ParseSegment[T] box] box, si: USize) ? =>
    _segs = segs
    _si = si
    _sl = if _si < _segs.size() then
      _segs(_si).begin()
    else
      None
    end

  new _from_orig(segs: Array[_ParseSegment[T] box] box, si: USize, sl: (ParseLoc[T] ref | None)) =>
    _segs = segs
    _si = si
    _sl = sl

  fun box segments(): Array[_ParseSegment[T] box] box => _segs

  fun box index(): USize => _si

  fun box has_next(): Bool ? =>
    match _sl
    | let loc: this->ParseLoc[T] ref =>
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
    | let loc: ParseLoc[T] =>
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

  fun box eq(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      match _sl
      | let la: ParseLoc[T] box =>
        match other'._sl
        | let lb: box->ParseLoc[T] =>
          res = la == lb
        end
      end
    end
    res

  fun box ne(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      match _sl
      | let la: ParseLoc[T] box =>
        match other'._sl
        | let lb: box->ParseLoc[T] =>
          res = la != lb
        end
      else
        res = not (other'._sl is None)
      end
    end
    res

  fun box lt(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      if _si < other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: ParseLoc[T] box =>
          match other'._sl
          | let lb: box->ParseLoc[T] =>
            res = la < lb
          end
        end
      end
    end
    res

  fun box le(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      if _si < other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: ParseLoc[T] box =>
          match other'._sl
          | let lb: box->ParseLoc[T] =>
            res = la <= lb
          end
        end
      end
    end
    res

  fun box ge(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      if _si > other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: ParseLoc[T] box =>
          match other'._sl
          | let lb: box->ParseLoc[T] =>
            res = la >= lb
          end
        end
      end
    end
    res

  fun box gt(other: box->ParseLoc[T]): Bool =>
    var res = false
    try
      let other' = other as box->_ParseSourceLoc[T]
      if _si > other'._si then
        true
      elseif _si == other'._si then
        match _sl
        | let la: ParseLoc[T] box =>
          match other'._sl
          | let lb: box->ParseLoc[T] =>
            res = la > lb
          end
        end
      end
    end
    res

  fun box clone(): ParseLoc[T]^ =>
    let sl =
      match _sl
      | let loc: this->ParseLoc[T] => loc.clone()
      else None end

    let loc = _ParseSourceLoc[T]._from_orig(_segs, _si, sl)
    consume loc

  fun box string(): String iso^ =>
    var s = recover String() end
    s.append(_si.string())
    s.append(":")
    match _sl
    | let la: ParseLoc[T] box => s.append(la.string())
    else
      s.append("?")
    end
    consume s


class ParseSource[T] is _ParseSegment[T]
  let _segs: Array[_ParseSegment[T] box] ref

  new create(seqs: Seq[Seq[T] box] box) =>
    var segs = Array[_ParseSegment[T] box](seqs.size())
    for s in seqs.values() do
      let seg = _SeqSegment[T](s)
      segs.push(seg)
    end
    _segs = segs

  fun box begin(): ParseLoc[T]^ ? =>
    let loc = _ParseSourceLoc[T](_segs)
    consume loc

  fun begin_segment(i: USize): _ParseSourceLoc[T]^ ? =>
    let loc = _ParseSourceLoc[T].begin_segment(_segs, i)
    consume loc

  fun ref segments(): Array[_ParseSegment[T] box] ref =>
    _segs
