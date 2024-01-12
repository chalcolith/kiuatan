
use "pony_test"

use ".."

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestExampleMain)
    test(_TestLocEquality)
    test(_TestLocValues)
    test(_TestRuleAny)
    test(_TestRuleAnyClass)
    test(_TestRuleLiteralSingle)
    test(_TestRuleLiteralMulti)
    test(_TestRuleConj)
    test(_TestRuleConjInvalid)
    test(_TestRuleDisj)
    test(_TestRuleErr)
    test(_TestRuleLook)
    test(_TestRuleNeg)
    test(_TestRuleStarZero)
    test(_TestRuleStarMin)
    test(_TestRuleStarMax)
    test(_TestRuleStarChildren)
    test(_TestRuleForwardDeclare)
    test(_TestRuleLRImmediate)
    test(_TestRuleLRLeftAssoc)
    test(_TestRuleLRIndirect)
    test(_TestRuleVariableBind)
    test(_TestRuleCondition)
    test(_TestRuleData)
    test(_TestFlatten)
    test(_TestRuleBindStar)
    test(_TestRuleBindRecursive)
    test(_TestLookChildren)
