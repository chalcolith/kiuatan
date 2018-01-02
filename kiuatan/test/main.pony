
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
    test(_TestRuleNodeLiteral)
    test(_TestRuleNodeLiteralAction)
    test(_TestRuleNodeSequenceAction)
    test(_TestRuleNodeChoiceAction)
    test(_TestRuleNodeRepeatAction)
    test(_TestRuleNodeSequenceOperator)
    test(_TestRuleNodeChoiceOperator)
    test(_TestRuleNodeNot)
    test(_TestRuleNodeAnd)
    test(_TestParseLeftRecursion)
    test(_TestRuleNodeClass)
    test(_TestCalculator)
    test(_TestFarthestError)
    test(_TestLastError)
