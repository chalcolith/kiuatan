use "pony_test"
use ".."

class iso _TestFlatten is UnitTest
  fun name(): String => "Value_Flatten"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8,None,USize](
          "Three",
          Conj[U8,None,USize]([
            NamedRule[U8,None,USize]("OneTwo",
              Conj[U8,None,USize]([
                Literal[U8,None,USize]("one", {(_,_,_,_) => 1 })
                Literal[U8,None,USize]("two", {(_,_,_,_) => 2 })
              ]))
            Literal[U8,None,USize]("three", {(_,_,_,_) => 3 })
            NamedRule[U8,None,USize]("Four",
              Literal[U8,None,USize]("four", {(_,_,_,_) => 4 }))
          ])
          where memoize' = true)
      end

    let segment = "onetwothreefour"
    let parser = Parser[U8,None,USize]([segment])
    parser.parse(rule, None,
      {(result: Result[U8,None,USize], values: ReadSeq[USize]) =>
        match result
        | let success: Success[U8,None,USize] =>
          try
            h.assert_eq[USize](4, values.size())
            h.assert_eq[USize](1, values(0)?)
            h.assert_eq[USize](2, values(1)?)
            h.assert_eq[USize](3, values(2)?)
            h.assert_eq[USize](4, values(3)?)
          else
            h.fail("Wrong number of result values!")
          end
        | let failure: Failure[U8,None,USize] =>
          h.fail()
        end
      })
