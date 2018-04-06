
use "debug"
use "ponytest"
use ".."

class iso _TestExampleMain is UnitTest
  fun name(): String => "Example_Main"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ws = Rule[U8]("WhiteSpace", Star[U8](Single[U8](" \t"), 1))
        Rule[U8]("OneTwoThree",
          Conj[U8](
            [ Literal[U8]("one")
              ws
              Disj[U8]([ Literal[U8]("two"); Literal[U8]("deux") ])
              ws
              Literal[U8]("three")
            ]))
      end

    let segment = "one two three"
    let parser = Parser[U8]([segment])
    parser.parse(rule, {(result: Result[U8]) =>
      match result
      | let success: Success[U8] =>
        Debug.out("succeeded!")
      | let failure: Failure[U8] =>
        Debug.out("failed")
      end
    })
