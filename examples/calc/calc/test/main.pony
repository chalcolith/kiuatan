
use k = "kiuatan"
use "ponytest"
use calc = ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestGrammarInt)
    test(_TestGrammarFloatIntPart)


primitive _FloatTest
  fun should_succeed(h: TestHelper, expected: F64, result: k.Result[U8, F64]) =>
    match result
    | let success: k.Success[U8, F64] =>
      match success.value()
      | let actual: F64 =>
        h.assert_eq[F64](expected, actual)
      else
        h.fail("did not return a value")
      end
      h.complete(true)
    | let failure: k.Failure[U8, F64] =>
      h.fail(failure.message)
      h.complete(false)
    end



class iso _TestGrammarInt is UnitTest
  fun name(): String => "Grammar_Int"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.integer()
    let parser = k.Parser[U8, F64](["123"])
    parser.parse(rule, _FloatTest~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatIntPart is UnitTest
  fun name(): String => "Grammar_Float_IntPart"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["123"])
    parser.parse(rule, _FloatTest~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)
