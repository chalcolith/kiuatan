
use "ponytest"

use ".."

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestLocEquality)
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
    test(_TestRuleForwardDeclare)
    test(_TestRuleLRImmediate)
    test(_TestRuleLRIndirect)
    test(_TestExampleMain)
