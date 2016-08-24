use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestSourceSeqSegmentPrimitive)
    test(_TestSourceSeqSegmentString)
    test(_TestSourcePrimitive)


class iso _TestSourceSeqSegmentPrimitive is UnitTest
  fun name(): String => "Source_SeqSegment_Primitive"

  fun apply(h: TestHelper) ? =>
    let a: Array[U32] = [0, 1, 2, 3, 4]
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
    let a: Array[String] = ["one", "two", "three", "four"]
    let seg = _SeqSegment[String](a)
    let loc = seg.begin()
    for s in a.values() do
      h.assert_true(loc.has_next())
      h.assert_eq[String](s, loc.next())
    end
    h.assert_false(loc.has_next())


class iso _TestSourcePrimitive is UnitTest
  fun name(): String => "Source_Primitive"

  fun apply(h: TestHelper) ? =>
    let a1: Array[U32] = [0, 1, 2, 3]
    let a2: Array[U32] = [4, 5, 6, 7]
    let aa = Array[Seq[U32]](2)
    aa.push(a1)
    aa.push(a2)

    let src = Source[U32](aa)
    let loc = src.begin()
    var count: U32 = 0
    while loc.has_next() do
      h.assert_eq[U32](count = count + 1, loc.next())
    end
    h.assert_eq[U32](8, count)
