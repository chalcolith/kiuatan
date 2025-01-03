use "pony_test"

use ".."

class iso _TestLookChildren is UnitTest
  fun name(): String => "Look_Children"

  fun apply(h: TestHelper) =>
    let sub =
      recover val
        NamedRule[U8, None, USize](
          "sub",
          Literal[U8, None, USize]("a"),
          {(_, _, _, _) => 0 },
          true)
      end
    let rule =
      recover val
        NamedRule[U8, None, USize](
          "rule",
          Conj[U8, None, USize](
            [ Look[U8, None, USize](sub)
              sub ]),
          {(_, _, c, _) => c.size() },
          true)
      end

    let parser = Parser[U8, None, USize]([ "a" ])
    parser.parse(
      rule,
      None,
      { (r, v) =>
        let num_children =
          try
            v(0)?
          else
            USize.max_value()
          end

        match r
        | let s: Success[U8, None, USize] box =>
          h.assert_eq[USize](1, num_children, "should be 1 child")
        else
          h.fail("failed to parse")
        end
        h.complete(true)
      })
    h.long_test(2_000_000_000)
