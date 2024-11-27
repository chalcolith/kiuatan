use "pony_test"
use ".."

class iso _TestExampleMain is UnitTest
  fun name(): String => "Example_Main"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ws = NamedRule[U8](
          "WhiteSpace", Star[U8](Single[U8](" \t"), 1)
          where memoize' = true)
        NamedRule[U8](
          "OneTwoThree",
          Conj[U8](
            [ Literal[U8]("one")
              ws
              Disj[U8]([ Literal[U8]("two"); Literal[U8]("deux") ])
              ws
              Literal[U8]("three")
            ])
            where memoize' = true)
      end

    let segment = "one two three"
    let parser = Parser[U8]([segment])
    parser.parse(rule, None,
      {(result: Result[U8], values: ReadSeq[None] val) =>
        match result
        | let success: Success[U8] =>
          h.complete(true)
        | let failure: Failure[U8] =>
          h.fail()
        end
      })
