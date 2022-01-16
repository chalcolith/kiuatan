use "ponytest"
use ".."

class iso _TestFlatten is UnitTest
  fun name(): String => "Flatten"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8,None,USize]("Three",
          Conj[U8,None,USize]([
            NamedRule[U8,None,USize]("OneTwo",
              Conj[U8,None,USize]([
                Literal[U8,None,USize]("one", {(r,_,b) => (USize(1),b)})
                Literal[U8,None,USize]("two", {(r,_,b) => (USize(2),b)})
              ]))
            Literal[U8,None,USize]("three", {(r,_,b) => (USize(3),b)})
            NamedRule[U8,None,USize]("Four",
              Literal[U8,None,USize]("four", {(r,_,b) => (USize(4),b)}))
          ]))
      end

    let segment = "onetwothreefour"
    let parser = Parser[U8,None,USize]([segment])
    parser.parse(rule, None,
      {(result: Result[U8,None,USize], values: ReadSeq[USize] val) =>
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
