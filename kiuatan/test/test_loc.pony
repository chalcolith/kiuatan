
use "collections/persistent"
use "itertools"
use "pony_test"

use ".."

class iso _TestLocEquality is UnitTest
  fun name(): String => "Loc_Equality"

  fun apply(h: TestHelper) ? =>
    let seg0: ReadSeq[U32] val = [ 1; 2; 3; 4 ]
    let seg1: ReadSeq[U32] val = [ 5; 6; 7; 8 ]
    let source = Lists[ReadSeq[U32] val].from([ seg0; seg1 ].values())
    let a = Loc[U32](source, 1)
    let b = Loc[U32](source.tail()?, 2)
    let c = a.add(5)

    h.assert_eq[Loc[U32]](b, c)


class iso _TestLocValues is UnitTest
  fun name(): String => "Loc_Values"

  fun apply(h: TestHelper) ? =>
    let seg0: ReadSeq[U32] val = [ 1; 2; 3; 4 ]
    let seg1: ReadSeq[U32] val = [ 5; 6; 7; 8 ]
    let source = Lists[ReadSeq[U32] val].from([ seg0; seg1 ].values())
    let a = Loc[U32](source, 1)
    let b = Loc[U32](source.tail()?, 2)

    var i: U32 = 2
    for v in a.values() do
      h.assert_eq[U32](i, v)
      i = i + 1
    end
    h.assert_eq[U32](9, i)

    i = 2
    for v in a.values(b) do
      h.assert_eq[U32](i, v)
      i = i + 1
    end
    h.assert_eq[U32](7, i)
