use "collections"

class ParseLoc[T] is (Equatable[ParseLoc[T]] & Stringable)
  """
  A pointer to a particular location in list of source sequences.
  """

  var _node: ListNode[ReadSeq[T]] box
  var _index: USize

  new create(node': ListNode[ReadSeq[T]] box, index': USize = 0) =>
    _node = node'
    _index = index'

  fun box node() =>
    _node

  fun box index() =>
    _index

  fun has_next(): Bool =>
    try
      if _index < _node().size() then
        return true
      elseif _node.has_next() then
        let n = _node.next() as ListNode[ReadSeq[T]] box
        return n().size() > 0
      end
    end
    false

  fun ref next(): box->T ? =>
    var seq = _node()
    if _index >= seq.size() then
      _node = _node.next() as ListNode[ReadSeq[T]] box
      _index = 0
      seq = _node()
    end
    seq(_index = _index + 1)

  fun box clone(): ParseLoc[T]^ =>
    ParseLoc[T](_node, _index)

  fun box add(n: USize): ParseLoc[T]^ ? =>
    let cur = clone()
    var i: USize = 0
    while i < n do
      cur.next()
      i = i + 1
    end
    consume cur

  fun box eq(that: box->ParseLoc[T]) : Bool =>
    (_node is that._node) and (_index == that._index)

  fun box ne(that: box->ParseLoc[T]) : Bool =>
    not ((_node is that._node) and (_index == that._index))

  fun box string(): String iso^ =>
    var num: USize = 0
    try
      var cur: ListNode[ReadSeq[T]] box = _node
      while cur.has_prev() do
        num = num + 1
        cur = cur.prev() as ListNode[ReadSeq[T]] box
      end
    end
    var s = recover String end
    s.append(num.string())
    s.append(":")
    s.append(_index.string())
    consume s
