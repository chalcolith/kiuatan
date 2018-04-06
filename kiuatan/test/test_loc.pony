
use "collections/persistent"
use "itertools"
use "ponytest"

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
