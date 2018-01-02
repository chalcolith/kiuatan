
use "collections"
use "debug"
use "itertools"
use "ponytest"

use ".."

class iso _TestLastError is UnitTest
  fun name(): String => "LastError"

  fun apply(h: TestHelper) ? =>
    let errmsg1 = "expected 'vu'"
    let errmsg2 = "expected 'ab'"
    let grammar = 
      ParseRule[U8](
        "G",
        RuleChoice[U8](
          [ RuleSequence[U8](
              [ RuleLiteral[U8]("zy")
                RuleLiteral[U8]("xw")
                RuleChoice[U8]([ RuleLiteral[U8]("vu"); RuleError[U8](errmsg1) ])
              ])
            RuleSequence[U8](
              [ RuleLiteral[U8]("zy")
                RuleChoice[U8]([ RuleLiteral[U8]("ab"); RuleError[U8](errmsg2) ])
              ])
          ]))

    let state = ParseState[U8].from_single_seq("zyxwrr")
    match state.parse(grammar)
    | None =>
      match state.farthest_error()
      | let err: ParseError[U8] =>
        h.assert_eq[String](errmsg1, err.messages.values().next()?)
      else
        h.fail("farthest error not found")
      end
      match state.last_error()
      | let err: ParseError[U8] =>
        h.assert_eq[String](errmsg2, err.messages.values().next()?)
      else
        h.fail("last error not found")
      end
    else
      h.fail("text should not parse")
    end

class iso _TestFarthestError is UnitTest
  fun name(): String => "FarthestError"

  fun apply(h: TestHelper) ? =>
    let errmsg = "expected 'cd'"

    let grammar = 
      ParseRule[U8](
        "G",
        RuleSequence[U8](
          [ RuleLiteral[U8]("ab")
            RuleChoice[U8](
              [ RuleLiteral[U8]("cd")
                RuleError[U8](errmsg)
              ])
          ]))

    let state1 = ParseState[U8].from_single_seq("abcd")
    match state1.parse(grammar)
    | None => h.fail("'abcd' failed to match 'ab' + 'cd'")
    end

    let state2 = ParseState[U8].from_single_seq("abzz")
    match state2.parse(grammar)
    | None =>
      match state2.farthest_error()
      | let err: ParseError[U8] =>
        h.assert_eq[String](errmsg, err.messages.values().next()?)
      else
        h.fail("'abzz': farthest error not found")
      end
    else
      h.fail("'abzz' erroneously matched 'ab' + 'cd'")
    end


class iso _TestCalculator is UnitTest
  let _grammar: ParseRule[U8,ISize] = Calculator.generate()

  fun name(): String => "Calculator"

  fun apply(h: TestHelper) =>
    _run_test(h, "123", 123)
    _run_test(h, "123 + (4 * 12)", 123 + (4 * 12))

  fun _run_test(h: TestHelper, input: String, expected: ISize) =>
    let state = ParseState[U8,ISize].from_single_seq(input)
    let result = state.parse(_grammar)
    match result
    | let result': ParseResult[U8,ISize] =>
      match result'.value()
      | let actual: ISize =>
        if actual == expected then
          h.log("ok:   " + input + " => " + expected.string())
        else
          h.fail("FAIL: " + input + " => " + actual.string()
            + " expected " + expected.string())
        end
        return
      end
    end
    h.fail("FAIL: no result")


class iso _TestRuleNodeClass is UnitTest
  fun name(): String => "RuleNode_Class"

  fun apply(h: TestHelper) =>
    let ab = RuleLiteral[U8]("ab")
    let bcde = RuleClass[U8].from_iter("bcde".values())
    let fg = RuleLiteral[U8]("fg")
    let rule = ParseRule[U8]("Rule", RuleSequence[U8, None]([ab; bcde; fg]))

    let state1 = ParseState[U8].from_single_seq("abbfg")
    match state1.parse(rule)
    | None => h.fail("state1 did not match")
    end

    let state2 = ParseState[U8].from_single_seq("abefg")
    match state2.parse(rule)
    | None => h.fail("state2 did not match")
    end


class iso _TestParseLeftRecursion is UnitTest
  fun name(): String => "Parse_LeftRecursion"

  fun apply(h: TestHelper) =>
    // A = A + "cd" | "ab"
    let ab = RuleLiteral[U8]("ab")
    let cd = RuleLiteral[U8]("cd")

    let a = ParseRule[U8]("A")
    a.set_child(RuleChoice[U8]([ RuleSequence[U8]([ a; cd ]); ab ]))

    Debug.out("RULE A is " + a.description())

    let state = ParseState[U8].from_single_seq("abcd")
    match state.parse(a)
    | None => h.fail("recursive rule did not match")
    end


class iso _TestRuleNodeAnd is UnitTest
  fun name(): String => "RuleNode_And"

  fun apply(h: TestHelper) =>
    let rule = ParseRule[U8]("R", RuleAnd[U8](RuleLiteral[U8]("ab"))
      + RuleLiteral[U8]("abcd"))

    let state = ParseState[U8].from_single_seq("abcd")
    match state.parse(rule)
    | None => h.fail("&ab+abcd rule did not match \"abcd\"")
    end


class iso _TestRuleNodeNot is UnitTest
  fun name(): String => "RuleNode_Not"

  fun apply(h: TestHelper) =>
    let rule = ParseRule[U8]("R", RuleNot[U8](RuleLiteral[U8]("ab"))
      + RuleLiteral[U8]("cde"))

    let state = ParseState[U8].from_single_seq("cde")
    match state.parse(rule)
    | None => h.fail("!ab+cde rule did not match \"cde\"")
    end


class iso _TestRuleNodeChoiceOperator is UnitTest
  fun name(): String => "RuleNode_Choice_Operator"

  fun apply(h: TestHelper) =>
    let ab_or_bc_rule = ParseRule[U8]("R", RuleLiteral[U8]("ab")
      or RuleLiteral[U8]("bc"))

    let match_ab = ParseState[U8].from_single_seq("ab")
    match match_ab.parse(ab_or_bc_rule)
    | None => h.fail("ab|bc choice did not match \"ab\"")
    end

    let match_bc = ParseState[U8].from_single_seq("bc")
    match match_bc.parse(ab_or_bc_rule)
    | None => h.fail("ab|bc choice did not match \"bc\"")
    end

    let match_de = ParseState[U8].from_single_seq("de")
    match match_de.parse(ab_or_bc_rule)
    | None => None
    else
      h.fail("ab|bc choice matched \"de\" erroneously")
    end


class iso _TestRuleNodeSequenceOperator is UnitTest
  fun name(): String => "RuleNode_Sequence_Operator"

  fun apply(h: TestHelper) =>
    let ab_rule = ParseRule[U8]("R", RuleLiteral[U8]("a") 
      + RuleLiteral[U8]("b"))

    let should_match = ParseState[U8].from_single_seq("ab")
    match should_match.parse(ab_rule)
    | None => h.fail("ab sequence did not match \"ab\"")
    end

    let should_not_match = ParseState[U8].from_single_seq("cd")
    match should_not_match.parse(ab_rule)
    | None => None
    else
      h.fail("ab sequence matched \"cd\" erroneously")
    end


class iso _TestRuleNodeRepeatAction is UnitTest
  fun name(): String => "RuleNode_Repeat_Action"

  fun apply(h: TestHelper) =>
    let child = RuleLiteral[U8,U8]("x")
    let rep0 = ParseRule[U8,U8]("R", RuleRepeat[U8,U8](child, None, 0))

    let memo0_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))
    match memo0_0.parse(rep0)
    | None => h.fail("repeat 0 did not match 0")
    end

    let memo0_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "x"]))
    match memo0_1.parse(rep0)
    | None => h.fail("repeat 0 did not match 1")
    end

    let rep1 = ParseRule[U8,U8]("R", RuleRepeat[U8,U8](child, None, 1))

    let memo1_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))
    match memo1_0.parse(rep1)
    | let _: ParseResult[U8,U8] => h.fail("repeat 1 matched 0")
    end

    let memo1_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "xx"]))
    match memo1_1.parse(rep1)
    | let r: ParseResult[U8,U8] =>
      let n = r.results.size()
      h.assert_eq[USize](2, n, "repeat 1 did not match 2 xes")
    | None => h.fail("repeat 1 did not match 2")
    end


class iso _TestRuleNodeChoiceAction is UnitTest
  fun name(): String => "RuleNode_Choice_Action"

  fun apply(h: TestHelper) =>
    let a_rule = RuleLiteral[U8,U8]("a")
    let b_rule = RuleLiteral[U8,U8]("b")
    let c_rule = RuleLiteral[U8,U8]("c")

    let rules = [as RuleNode[U8,U8]: a_rule; b_rule; c_rule]
    let choice = ParseRule[U8,U8]("C", RuleChoice[U8,U8](rules))

    let memo1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))
    match memo1.parse(choice)
    | None => h.fail("choice a did not match")
    end

    let memo2 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "b"]))
    match memo2.parse(choice)
    | None => h.fail("choice b did not match")
    end

    let memo3 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "c"]))
    match memo3.parse(choice)
    | None => h.fail("choice c did not match")
    end

    let memo4 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "z"]))
    match memo4.parse(choice)
    | let _: ParseResult[U8,U8] => h.fail("choice z matched erroneously")
    end


class iso _TestRuleNodeSequenceAction is UnitTest
  fun name(): String => "RuleNode_Sequence_Action"

  fun apply(h: TestHelper) =>
    let any_rule = RuleAny[U8,USize](
      {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
        try
          let i = ctx.result.start.clone()
          let c = i.next()?
          if (c >= '0') and (c <= '9') then
            return USize.from[U8](c - '0')
          end
        end
        0
      })
    let rules =
      [ as RuleNode[U8,USize] box:
        any_rule; any_rule; any_rule; any_rule; any_rule]

    let seq_rule = 
      ParseRule[U8,USize](
        "Seq",
        RuleSequence[U8,USize](
          rules,
          {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
            var sum: USize = 0
            for r in ctx.result.results.values() do
              match r.value()
              | let n: USize => sum = sum + n
              end
            end
            sum
          }))

    let seg1 = "12345"
    let src = List[ReadSeq[U8]].from([as ReadSeq[U8]: seg1])
    let memo = ParseState[U8,USize](src)
    let result = memo.parse(seq_rule)

    match result
    | None => h.fail("sequence did not match")
    | let r: ParseResult[U8,USize] =>
      match r.value()
      | let sum: USize =>
        h.assert_eq[USize](15, sum,
          "sequence action did not return the correct value")
      else
        h.fail("action did not return a value")
      end
    end


class iso _TestRuleNodeLiteralAction is UnitTest
  fun name(): String => "RuleNode_Literal_Action"

  fun apply(h: TestHelper) ? =>
    let seg1 = "123 456 789"
    let segs = [as ReadSeq[U8]: seg1]
    let src = List[ReadSeq[U8]].from(segs)

    let str = "123"
    let memo = ParseState[U8,USize](src)
    let literal = 
      ParseRule[U8,USize](
        "Literal",
        RuleLiteral[U8,USize](
          str,
          {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
            try
              let s = String
              let i = ctx.result.start.clone()
              while i.has_next() and (i != ctx.result.next) do
                s.push(i.next()?)
              end
              s.usize()?
            else
              -1
            end
          }))
    let result = memo.parse(literal)

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8,USize] =>
      let start = memo.start()?
      let next = start +? str.size()
      h.assert_eq[ParseLoc[U8] box](start, result'.start, "match does not start at the correct loc")
      h.assert_eq[ParseLoc[U8] box](next, result'.next, "match does not end at the correct loc")
      match result'.value()
      | let num: USize =>
        h.assert_eq[USize](123, num, "action did not return the correct result")
      else
        h.fail("action did not return a value")
      end
    end


class iso _TestRuleNodeLiteral is UnitTest
  fun name(): String => "RuleNode_Literal"

  fun apply(h: TestHelper) ? =>
    let seg1 = "one two three"
    let segs = [ as ReadSeq[U8]: seg1 ]
    let src = List[ReadSeq[U8]].from(segs)

    let str = "one"
    let memo = ParseState[U8](src)
    let literal = ParseRule[U8]("L", RuleLiteral[U8](str))
    let result = memo.parse(literal)

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8] =>
      let start = memo.start()?
      let next = start +? str.size()
      h.assert_eq[ParseLoc[U8] box](start, result'.start, "match does not start at the correct loc")
      h.assert_eq[ParseLoc[U8] box](next, result'.next, "match does not end at the correct loc")
    end


class iso _TestParseLocPrimitive is UnitTest
  fun name(): String => "ParseLoc_Primitive"

  fun apply(h: TestHelper) ? =>
    let seq = [as U32: 0; 1; 2; 3; 4]
    let loc = ParseLoc[U32](ListNode[ReadSeq[U32]](seq), 0)
    for n in seq.values() do
      h.assert_true(loc.has_next())
      h.assert_eq[U32](n, loc.next()?)
    end
    h.assert_false(loc.has_next())


class iso _TestParseLocClass is UnitTest
  fun name(): String => "ParseLoc_Class"

  fun apply(h: TestHelper) ? =>
    let seq = ["one"; "two"; "three"; "four"]
    let loc = ParseLoc[String](ListNode[ReadSeq[String]](seq), 0)
    for s in seq.values() do
      h.assert_true(loc.has_next())
      h.assert_eq[String](s, loc.next()?)
    end
    h.assert_false(loc.has_next())


class iso _TestParseLocListPrimitive is UnitTest
  fun name(): String => "ParseLoc_List_Primitive"

  fun apply(h: TestHelper) ? =>
    let a1 = [as U32: 0; 1; 2; 3]
    let a2 = [as U32: 4; 5; 6; 7]
    let aa = [as ReadSeq[U32]: a1; a2]

    let actual = List[ReadSeq[U32]].from(aa)
    let loc = ParseLoc[U32](actual.head()?)

    let expected = Iter[U32].chain([a1.values(); a2.values()].values())

    for e in expected do
      h.assert_true(loc.has_next())
      h.assert_eq[U32](e, loc.next()?)
    end
    h.assert_false(loc.has_next())
