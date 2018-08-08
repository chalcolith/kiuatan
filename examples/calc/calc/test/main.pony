
use k = "kiuatan"
use "ponytest"
use calc = ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestGrammarInt)


class iso _TestGrammarInt is UnitTest
  fun name(): String => "Grammar_Int"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.integer()
    let parser = k.Parser[U8, F64](["123"])
    parser.parse(rule, {(result) =>
      match result
      | let success: k.Success[U8, F64] =>
        match success.value()
        | let num: F64 =>
          h.assert_eq[F64](123.0, num)
        else
          h.fail("did not return a value")
        end
        h.complete(true)
      | let failure: k.Failure[U8, F64] =>
        h.fail(failure.message)
        h.complete(false)
      end
    })
    h.long_test(10_000_000_000)
