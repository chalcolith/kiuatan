use "debug"
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestSourceSeqSegmentPrimitive)
    test(_TestSourceSeqSegmentString)
    test(_TestSourceSourcePrimitive)


class iso _TestSourceSeqSegmentPrimitive is UnitTest
  fun name(): String => "Source_SeqSegment_Primitive"

  fun apply(h: TestHelper) ? =>
    let a = [as U32: 0, 1, 2, 3, 4]
    let seg = _SeqSegment[U32](a)
    let loc = seg.begin()
    for n in a.values() do
      h.assert_true(loc.has_next())
      h.assert_eq[U32](n, loc.next())
    end
    h.assert_false(loc.has_next())


class iso _TestSourceSeqSegmentString is UnitTest
  fun name(): String => "Source_SeqSegment_String"

  fun apply(h: TestHelper) ? =>
    let a = ["one", "two", "three", "four"]
    let seg = _SeqSegment[String](a)
    let loc = seg.begin()
    for s in a.values() do
      h.assert_true(loc.has_next())
      h.assert_eq[String](s, loc.next())
    end
    h.assert_false(loc.has_next())


class iso _TestSourceSourcePrimitive is UnitTest
  fun name(): String => "Source_Source_Primitive"

  fun apply(h: TestHelper) ? =>
    let a1 = [as U32: 0, 1, 2, 3]
    let a2 = [as U32: 4, 5, 6, 7]
    let aa = [as Seq[U32] box: a1, a2]

    let src = ParseSource[U32](aa)
    let loc = src.begin_segment(0)
    var count: U32 = 0
    while loc.has_next() do
      let item = loc.next()
      let idx = loc.index()
      if count < 4 then
        h.assert_eq[USize](0, idx)
      else
        h.assert_eq[USize](1, idx)
      end
      h.assert_eq[U32](count = count + 1, item)
    end
    h.assert_eq[U32](8, count)


class iso _TestGrammarRuleLiteral is UnitTest
  fun name(): String => "GrammarRule_Literal"

  fun apply(h: TestHelper) ? =>
    let seg1 = "one two three"
    let segs = [as Seq[U8] box: seg1]
    let src = ParseSource[U8](segs)

    let str = "one"
    let memo = ParseState[U8,None](src)
    let literal = GrammarLiteral[U8,None](str)
    let result = literal.parse(memo, src.begin())

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8,None] =>
      let start = src.begin()
      let next = start + str.size()
      h.assert_eq[ParseLoc[U8] box](start, result'.start, "match does not start at the correct loc")
      h.assert_eq[ParseLoc[U8] box](next, result'.next, "match does not end at the correct loc")
    end
