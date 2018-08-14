
use k = "kiuatan"
use "ponytest"
use calc = ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestGrammarSpace)
    test(_TestGrammarSpaceFail)
    test(_TestGrammarEOF)
    test(_TestGrammarEOFFail)
    test(_TestGrammarInt)
    test(_TestGrammarIntNeg)
    test(_TestGrammarFloatBlank)
    test(_TestGrammarFloatSpace)
    test(_TestGrammarFloatIntPart)
    test(_TestGrammarFloatDecimal)
    test(_TestGrammarFloatDecimalNeg)
    test(_TestGrammarFloatExponent)
    test(_TestGrammarFloatExponentNeg)


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

  fun should_span(h: TestHelper, len: USize, result: k.Result[U8, F64]) =>
    match result
    | let success: k.Success[U8, F64] =>
      h.assert_eq[k.Loc[U8]](success.start + len, success.next,
        "lengths differ")
      h.complete(true)
    else
      h.fail("should have succeeded")
    end

  fun should_fail(h: TestHelper, result: k.Result[U8, F64]) =>
    match result
    | let success: k.Success[U8, F64] =>
      h.fail("expected failure; returned a value")
      h.complete(false)
    | let failure: k.Failure[U8, F64] =>
      h.complete(true)
    end


class iso _TestGrammarSpace is UnitTest
  fun name(): String => "Grammar_Space"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.space()
    let parser = k.Parser[U8, F64]([" \t"])
    parser.parse(rule, _FloatTest~should_span(h, 2))
    h.long_test(10_000_000_000)


class iso _TestGrammarSpaceFail is UnitTest
  fun name(): String => "Grammar_Space_Fail"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.space()
    let parser = k.Parser[U8, F64](["abc"])
    parser.parse(rule, _FloatTest~should_span(h, 0))
    h.long_test(10_000_000_000)


class iso _TestGrammarEOF is UnitTest
  fun name(): String => "Grammar_EOF"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.eof()
    let parser = k.Parser[U8, F64]([""])
    parser.parse(rule, _FloatTest~should_span(h, 0))
    h.long_test(10_000_000_000)


class iso _TestGrammarEOFFail is UnitTest
  fun name(): String => "Grammar_EOF_Fail"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.eof()
    let parser = k.Parser[U8, F64](["abc"])
    parser.parse(rule, _FloatTest~should_fail(h))
    h.long_test(10_000_000_000)


class iso _TestGrammarInt is UnitTest
  fun name(): String => "Grammar_Int"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.integer()
    let parser = k.Parser[U8, F64](["123"])
    parser.parse(rule, _FloatTest~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarIntNeg is UnitTest
  fun name(): String => "Grammar_Int_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.integer()
    let parser = k.Parser[U8, F64](["-321"])
    parser.parse(rule, _FloatTest~should_succeed(h, -321.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatBlank is UnitTest
  fun name(): String => "Grammar_Float_Blank"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64]([""])
    parser.parse(rule, _FloatTest~should_fail(h))


class iso _TestGrammarFloatSpace is UnitTest
  fun name(): String => "Grammar_Float_Space"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64]([" \t"])
    parser.parse(rule, _FloatTest~should_fail(h))


class iso _TestGrammarFloatIntPart is UnitTest
  fun name(): String => "Grammar_Float_IntPart"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["123"])
    parser.parse(rule, _FloatTest~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatDecimal is UnitTest
  fun name(): String => "Grammar_Float_Decimal"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["123.456"])
    parser.parse(rule, _FloatTest~should_succeed(h, 123.456))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatDecimalNeg is UnitTest
  fun name(): String => "Grammar_Float_Decimal_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["-324.111"])
    parser.parse(rule, _FloatTest~should_succeed(h, -324.111))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatExponent is UnitTest
  fun name(): String => "Grammar_Float_Exponent"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["-675.22e12"])
    parser.parse(rule, _FloatTest~should_succeed(h, -675.22e12))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatExponentNeg is UnitTest
  fun name(): String => "Grammar_Float_Exponent_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.Grammar.float()
    let parser = k.Parser[U8, F64](["8876e-33"])
    parser.parse(rule, _FloatTest~should_succeed(h, 8876e-33))
    h.long_test(10_000_000_000)
