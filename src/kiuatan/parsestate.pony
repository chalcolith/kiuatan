use "collections"

class ParseState[TSrc,TRes]
  """
  Stores the memo and matcher stack for a particular match.
  """

  let _source: List[ReadSeq[TSrc]] box
  let _start: ParseLoc[TSrc] box

  let _memo_tables: Array[_MemoTable[TSrc,TRes]] = _memo_tables.create()

  new create(source': List[ReadSeq[TSrc]] box, start': (ParseLoc[TSrc] | None) = None) ? =>
    _source = source'
    match start'
    | let loc: ParseLoc[TSrc] =>
      _start = loc.clone()
    else
      _start = ParseLoc[TSrc](_source.head(), 0)
    end

  fun box source(): List[ReadSeq[TSrc] box] box =>
    _source

  fun box start(): ParseLoc[TSrc] box =>
    _start


class _MemoTable[TSrc,TRes]
  let node: ListNode[ReadSeq[TSrc]] tag
  let memo: Map[_Expansion, Map[USize, ParseResult[TSrc, TRes]]] = memo.create()

  new create(node': ListNode[ReadSeq[TSrc]] tag) =>
    node = node'


class _Expansion is (Hashable & Equatable[_Expansion])
  let name: String box
  let num: USize

  new create(name': String, num': USize) =>
    name = name'
    num = num'

  fun box hash(): U64 =>
    name.hash() xor num.hash()

  fun box eq(other: box->_Expansion): Bool =>
    (name == other.name) and (num == other.num)
