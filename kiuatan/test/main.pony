
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestParseLocPrimitive)
    test(_TestParseLocClass)
    test(_TestParseLocListPrimitive)
    test(_TestParseRuleLiteral)
    test(_TestParseRuleLiteralAction)
    test(_TestParseRuleSequenceAction)
    test(_TestParseRuleChoiceAction)
    test(_TestParseRuleRepeatAction)
    test(_TestParseRuleSequenceOperator)
    test(_TestParseRuleChoiceOperator)
    test(_TestParseRuleNot)
    test(_TestParseRuleAnd)
    test(_TestParseLeftRecursion)
    test(_TestParseRuleClass)
    test(_TestCalculator)
    test(_TestFarthestError)
    test(_TestLastError)
