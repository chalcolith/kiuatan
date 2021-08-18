
use k = "../../../../kiuatan"
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
    test(_TestGrammarMultiplicativeMul)
    test(_TestGrammarMultiplicativeDiv)
    test(_TestGrammarAdditiveAdd)
    test(_TestGrammarAdditiveSub)
    test(_TestGrammarPrecedence)
    test(_TestGrammarParens)
    test(_TestGrammarLeftAssoc)
    test(_TestGrammarSequences)


type Loc is k.Loc[U8]
type Parser is k.Parser[U8, None, F64]
type Result is k.Result[U8, None, F64]
type Success is k.Success[U8, None, F64]
type Failure is k.Failure[U8, None, F64]


primitive _Test
  fun should_succeed(h: TestHelper, expected: F64, result: Result,
    value: (F64 | None))
  =>
    match result
    | let success: Success =>
      match value
      | let actual: F64 =>
        assert_feq(h, expected, actual)
      else
        h.fail("did not return a value")
      end
      h.complete(true)
    | let failure: Failure =>
      h.fail(failure.get_message())
      h.complete(false)
    end

  fun should_span(h: TestHelper, len: USize, result: Result,
    value: (F64 | None))
  =>
    match result
    | let success: Success =>
      h.assert_eq[Loc](success.start + len, success.next,
        "lengths differ")
      h.complete(true)
    else
      h.fail("should have succeeded")
    end

  fun should_fail(h: TestHelper, result: Result, value: (F64 | None)) =>
    match result
    | let success: Success =>
      h.fail("expected failure; returned a value")
      h.complete(false)
    | let failure: Failure =>
      h.complete(true)
    end

  fun assert_feq(h: TestHelper, a: F64, b: F64) =>
    h.assert_true((a - b).abs() < 1.0e-6,
      "expected " + a.string() + " == " + b.string())


class iso _TestGrammarSpace is UnitTest
  fun name(): String => "Grammar_Space"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.space()
    let parser = Parser([" \t"])
    parser.parse(rule, None, _Test~should_span(h, 2))
    h.long_test(10_000_000_000)


class iso _TestGrammarSpaceFail is UnitTest
  fun name(): String => "Grammar_Space_Fail"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.space()
    let parser = Parser(["abc"])
    parser.parse(rule, None, _Test~should_span(h, 0))
    h.long_test(10_000_000_000)


class iso _TestGrammarEOF is UnitTest
  fun name(): String => "Grammar_EOF"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.eof()
    let parser = Parser([""])
    parser.parse(rule, None, _Test~should_span(h, 0))
    h.long_test(10_000_000_000)


class iso _TestGrammarEOFFail is UnitTest
  fun name(): String => "Grammar_EOF_Fail"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.eof()
    let parser = Parser(["abc"])
    parser.parse(rule, None, _Test~should_fail(h))
    h.long_test(10_000_000_000)


class iso _TestGrammarInt is UnitTest
  fun name(): String => "Grammar_Int"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.integer()
    let parser = Parser(["123"])
    parser.parse(rule, None, _Test~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarIntNeg is UnitTest
  fun name(): String => "Grammar_Int_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.integer()
    let parser = Parser(["-321"])
    parser.parse(rule, None, _Test~should_succeed(h, -321.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatBlank is UnitTest
  fun name(): String => "Grammar_Float_Blank"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser([""])
    parser.parse(rule, None, _Test~should_fail(h))


class iso _TestGrammarFloatSpace is UnitTest
  fun name(): String => "Grammar_Float_Space"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser([" \t"])
    parser.parse(rule, None, _Test~should_fail(h))


class iso _TestGrammarFloatIntPart is UnitTest
  fun name(): String => "Grammar_Float_IntPart"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser(["123"])
    parser.parse(rule, None, _Test~should_succeed(h, 123.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatDecimal is UnitTest
  fun name(): String => "Grammar_Float_Decimal"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser(["123.456"])
    parser.parse(rule, None, _Test~should_succeed(h, 123.456))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatDecimalNeg is UnitTest
  fun name(): String => "Grammar_Float_Decimal_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser(["-324.111"])
    parser.parse(rule, None, _Test~should_succeed(h, -324.111))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatExponent is UnitTest
  fun name(): String => "Grammar_Float_Exponent"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser(["-675.22e12"])
    parser.parse(rule, None, _Test~should_succeed(h, -675.22e12))
    h.long_test(10_000_000_000)


class iso _TestGrammarFloatExponentNeg is UnitTest
  fun name(): String => "Grammar_Float_Exponent_Neg"

  fun apply(h: TestHelper) =>
    let rule = calc.GrammarBuilder.float()
    let parser = Parser(["8876e-33"])
    parser.parse(rule, None, _Test~should_succeed(h, 8876e-33))
    h.long_test(10_000_000_000)


class iso _TestGrammarMultiplicativeMul is UnitTest
  fun name(): String => "Grammar_Multiplicative_Mul"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.multiplicative() end
    let parser = Parser(["123.4 * 567.8"])
    parser.parse(rule, None, _Test~should_succeed(h, 70066.52))
    h.long_test(10_000_000_000)


class iso _TestGrammarMultiplicativeDiv is UnitTest
  fun name(): String => "Grammar_Multiplicative_Div"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.multiplicative() end
    let parser = Parser(["123.4 / 567.8"])
    parser.parse(rule, None, _Test~should_succeed(h, 0.21733004579))
    h.long_test(10_000_000_000)


class iso _TestGrammarAdditiveAdd is UnitTest
  fun name(): String => "Grammar_Additive_Add"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.additive() end
    let parser = Parser(["123.4 + 567.8"])
    parser.parse(rule, None, _Test~should_succeed(h, 691.2))
    h.long_test(10_000_000_000)


class iso _TestGrammarAdditiveSub is UnitTest
  fun name(): String => "Grammar_Additive_Sub"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.additive() end
    let parser = Parser(["123.4 - 567.8"])
    parser.parse(rule, None, _Test~should_succeed(h, -444.4))
    h.long_test(10_000_000_000)


class iso _TestGrammarPrecedence is UnitTest
  fun name(): String => "Grammar_Precedence"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.expression() end
    let parser = Parser(["12 + 34 * 56"])
    parser.parse(rule, None, _Test~should_succeed(h, 1916.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarParens is UnitTest
  fun name(): String => "Grammar_Parens"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.expression() end
    let parser = Parser(["(12 + 34) * 56"])
    parser.parse(rule, None, _Test~should_succeed(h, 2576.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarLeftAssoc is UnitTest
  fun name(): String => "Grammar_LeftAssoc"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.expression() end
    let parser = Parser(["1*2*3"])
    parser.parse(rule, None, _Test~should_succeed(h, 6.0))
    h.long_test(10_000_000_000)


class iso _TestGrammarSequences is UnitTest
  fun name(): String => "Grammar_Sequences"

  fun apply(h: TestHelper) =>
    let rule = recover val calc.GrammarBuilder.expression() end
    let parser = Parser(["123.456 * (789.012e-12 + 345.6 - 78.90) / 12.34"])
    parser.parse(rule, None, _Test~should_succeed(h, 2668.21030795))
    h.long_test(10_000_000_000)
