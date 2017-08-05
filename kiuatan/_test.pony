use "collections"
use "debug"
use "itertools"
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


class iso _TestParseRuleClass is UnitTest
  fun name(): String => "ParseRule_Class"

  fun apply(h: TestHelper) ? =>
    let ab = RuleLiteral[U8]("ab")
    let bcde = RuleClass[U8].from_iter("bcde".values())
    let fg = RuleLiteral[U8]("fg")
    let rule = RuleSequence[U8, None]([ab; bcde; fg])

    let state1 = ParseState[U8].from_seq("abbfg")?
    match state1.parse(rule, state1.start())?
    | None => h.fail("state1 did not match")
    end

    let state2 = ParseState[U8].from_seq("abefg")?
    match state2.parse(rule, state2.start())?
    | None => h.fail("state2 did not match")
    end


class iso _TestParseLeftRecursion is UnitTest
  fun name(): String => "Parse_LeftRecursion"

  fun apply(h: TestHelper) ? =>
    // A = A + "cd" | "ab"
    let ab = RuleLiteral[U8]("ab")
    let cd = RuleLiteral[U8]("cd")

    let a = RuleChoice[U8](where name' = "A")
    let first = RuleSequence[U8]([ a; cd ])
    a.push(first)
    a.push(ab)

    Debug.out("RULE A is " + a.description())

    let state = ParseState[U8].from_seq("abcd")?
    match state.parse(a, state.start())?
    | None => h.fail("recursive rule did not match")
    end


class iso _TestParseRuleAnd is UnitTest
  fun name(): String => "ParseRule_And"

  fun apply(h: TestHelper) ? =>
    let rule = RuleAnd[U8](RuleLiteral[U8]("ab"))
      + RuleLiteral[U8]("abcd")

    let state = ParseState[U8].from_seq("abcd")?
    match state.parse(rule, state.start())?
    | None => h.fail("&ab+abcd rule did not match \"abcd\"")
    end


class iso _TestParseRuleNot is UnitTest
  fun name(): String => "ParseRule_Not"

  fun apply(h: TestHelper) ? =>
    let rule = RuleNot[U8](RuleLiteral[U8]("ab"))
      + RuleLiteral[U8]("cde")

    let state = ParseState[U8].from_seq("cde")?
    match state.parse(rule, state.start())?
    | None => h.fail("!ab+cde rule did not match \"cde\"")
    end


class iso _TestParseRuleChoiceOperator is UnitTest
  fun name(): String => "ParseRule_Choice_Operator"

  fun apply(h: TestHelper) ? =>
    let ab_or_bc_rule = RuleLiteral[U8]("ab")
      or RuleLiteral[U8]("bc")

    let match_ab = ParseState[U8].from_seq("ab")?
    match match_ab.parse(ab_or_bc_rule, match_ab.start())?
    | None => h.fail("ab|bc choice did not match \"ab\"")
    end

    let match_bc = ParseState[U8].from_seq("bc")?
    match match_bc.parse(ab_or_bc_rule, match_bc.start())?
    | None => h.fail("ab|bc choice did not match \"bc\"")
    end

    let match_de = ParseState[U8].from_seq("de")?
    match match_de.parse(ab_or_bc_rule, match_de.start())?
    | None => None
    else
      h.fail("ab|bc choice matched \"de\" erroneously")
    end


class iso _TestParseRuleSequenceOperator is UnitTest
  fun name(): String => "ParseRule_Sequence_Operator"

  fun apply(h: TestHelper) ? =>
    let ab_rule = RuleLiteral[U8]("a") + RuleLiteral[U8]("b")

    let should_match = ParseState[U8].from_seq("ab")?
    match should_match.parse(ab_rule, should_match.start())?
    | None => h.fail("ab sequence did not match \"ab\"")
    end

    let should_not_match = ParseState[U8].from_seq("cd")?
    match should_not_match.parse(ab_rule, should_not_match.start())?
    | None => None
    else
      h.fail("ab sequence matched \"cd\" erroneously")
    end


class iso _TestParseRuleRepeatAction is UnitTest
  fun name(): String => "ParseRule_Repeat_Action"

  fun apply(h: TestHelper) ? =>
    let child = RuleLiteral[U8,U8]("x")
    let rep0 = RuleRepeat[U8,U8](child, None, 0)

    let memo0_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match memo0_0.parse(rep0, memo0_0.start())?
    | None => h.fail("repeat 0 did not match 0")
    end

    let memo0_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "x"]))?
    match memo0_1.parse(rep0, memo0_1.start())?
    | None => h.fail("repeat 0 did not match 1")
    end

    let rep1 = RuleRepeat[U8,U8](child, None, 1)

    let memo1_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match memo1_0.parse(rep1, memo1_0.start())?
    | let _: ParseResult[U8,U8] => h.fail("repeat 1 matched 0")
    end

    let memo1_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "xx"]))?
    match memo1_1.parse(rep1, memo1_1.start())?
    | let r: ParseResult[U8,U8] =>
      let n = r.children.size()
      h.assert_eq[USize](2, n, "repeat 1 did not match 2 xes")
    | None => h.fail("repeat 1 did not match 2")
    end


class iso _TestParseRuleChoiceAction is UnitTest
  fun name(): String => "ParseRule_Choice_Action"

  fun apply(h: TestHelper) ? =>
    let a_rule = RuleLiteral[U8,U8]("a")
    let b_rule = RuleLiteral[U8,U8]("b")
    let c_rule = RuleLiteral[U8,U8]("c")

    let rules = [as ParseRule[U8,U8]: a_rule; b_rule; c_rule]
    let choice = RuleChoice[U8,U8](rules)

    let memo1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match memo1.parse(choice, memo1.start())?
    | None => h.fail("choice a did not match")
    end

    let memo2 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "b"]))?
    match memo2.parse(choice, memo2.start())?
    | None => h.fail("choice b did not match")
    end

    let memo3 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "c"]))?
    match memo3.parse(choice, memo3.start())?
    | None => h.fail("choice c did not match")
    end

    let memo4 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "z"]))?
    match memo4.parse(choice, memo4.start())?
    | let _: ParseResult[U8,U8] => h.fail("choice z matched erroneously")
    end


class iso _TestParseRuleSequenceAction is UnitTest
  fun name(): String => "ParseRule_Sequence_Action"

  fun apply(h: TestHelper) ? =>
    let any_rule = RuleAny[U8,USize](
      {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
        try
          let i = ctx.start.clone()
          let c = i.next()?
          if (c >= '0') and (c <= '9') then
            return USize.from[U8](c - '0')
          end
        end
        0
      })
    let rules =
      [ as ParseRule[U8,USize] box:
        any_rule; any_rule; any_rule; any_rule; any_rule]

    let seq_rule = RuleSequence[U8,USize](
      rules,
      "Seq",
      {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
        var sum: USize = 0
        for r in ctx.results.values() do
          match r.value()
          | let n: USize => sum = sum + n
          end
        end
        sum
      })

    let seg1 = "12345"
    let src = List[ReadSeq[U8]].from([as ReadSeq[U8]: seg1])
    let memo = ParseState[U8,USize](src)?
    let result = memo.parse(seq_rule, memo.start())?

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


class iso _TestParseRuleLiteralAction is UnitTest
  fun name(): String => "ParseRule_Literal_Action"

  fun apply(h: TestHelper) ? =>
    let seg1 = "123 456 789"
    let segs = [as ReadSeq[U8]: seg1]
    let src = List[ReadSeq[U8]].from(segs)

    let str = "123"
    let memo = ParseState[U8,USize](src)?
    let literal = RuleLiteral[U8,USize](
      str,
      {(ctx: ParseActionContext[U8,USize] box) : (USize | None) =>
        try
          let s = String
          let i = ctx.start.clone()
          while i.has_next() and (i != ctx.next) do
            s.push(i.next()?)
          end
          s.usize()?
        else
          -1
        end
      })
    let result = memo.parse(literal, memo.start())?

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8,USize] =>
      let start = memo.start()
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


class iso _TestParseRuleLiteral is UnitTest
  fun name(): String => "ParseRule_Literal"

  fun apply(h: TestHelper) ? =>
    let seg1 = "one two three"
    let segs = [ as ReadSeq[U8]: seg1 ]
    let src = List[ReadSeq[U8]].from(segs)

    let str = "one"
    let memo = ParseState[U8](src)?
    let literal = RuleLiteral[U8](str)
    let result = memo.parse(literal, memo.start())?

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8] =>
      let start = memo.start()
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

    let expected = Chain[U32]([a1.values(); a2.values()].values())

    for e in expected do
      h.assert_true(loc.has_next())
      h.assert_eq[U32](e, loc.next()?)
    end
    h.assert_false(loc.has_next())
