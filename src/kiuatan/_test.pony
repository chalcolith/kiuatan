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


class iso _TestParseRuleRepeatAction is UnitTest
  fun name(): String => "ParseRule_Repeat_Action"

  fun apply(h: TestHelper) ? =>
    let child = ParseLiteral[U8,U8]("x")
    let rep0 = ParseRepeat[U8,U8](child, 0)
    
    let memo0_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match rep0.parse(memo0_0, memo0_0.start())?
    | None => h.fail("repeat 0 did not match 0")
    end

    let memo0_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "x"]))?
    match rep0.parse(memo0_1, memo0_1.start())?
    | None => h.fail("repeat 0 did not match 1")
    end

    let rep1 = ParseRepeat[U8,U8](child, 1)

    let memo1_0 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match rep1.parse(memo1_0, memo1_0.start())?
    | let _: ParseResult[U8,U8] => h.fail("repeat 1 matched 0")
    end

    let memo1_1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "xx"]))?
    match rep1.parse(memo1_1, memo1_1.start())?
    | let r: ParseResult[U8,U8] =>
      let n = r.children.size()
      h.assert_eq[USize](2, n, "repeat 1 did not match 2 xes")
    | None => h.fail("repeat 1 did not match 2")
    end


class iso _TestParseRuleChoiceAction is UnitTest
  fun name(): String => "ParseRule_Choice_Action"

  fun apply(h: TestHelper) ? =>
    let a_rule = ParseLiteral[U8,U8]("a")
    let b_rule = ParseLiteral[U8,U8]("b")
    let c_rule = ParseLiteral[U8,U8]("c")

    let rules = [as ParseRule[U8,U8]: a_rule; b_rule; c_rule]
    let choice = ParseChoice[U8,U8](rules)

    let memo1 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "a"]))?
    match choice.parse(memo1, memo1.start())?
    | None => h.fail("choice a did not match")
    end

    let memo2 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "b"]))?
    match choice.parse(memo2, memo2.start())?
    | None => h.fail("choice b did not match")
    end

    let memo3 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "c"]))?
    match choice.parse(memo3, memo3.start())?
    | None => h.fail("choice c did not match")
    end

    let memo4 = ParseState[U8,U8](List[ReadSeq[U8]].from([as ReadSeq[U8]: "z"]))?
    match choice.parse(memo4, memo4.start())?
    | let _: ParseResult[U8,U8] => h.fail("choice z matched erroneously")
    end


class iso _TestParseRuleSequenceAction is UnitTest
  fun name(): String => "ParseRule_Sequence_Action"

  fun apply(h: TestHelper) ? =>
    let any_rule = ParseAny[U8,USize]({
      (ctx: ParseActionContext[U8,USize] box) : USize =>
        try
          let i = ctx.start.clone()
          let c = i.next()?
          if (c >= '0') and (c <= '9') then
            return USize.from[U8](c - '0')
          end
        end
        0
    })
    let rules = [as ParseRule[U8,USize]: any_rule; any_rule; any_rule; any_rule; any_rule]

    let seq_rule = ParseSequence[U8,USize]("Seq", rules, {
      (ctx: ParseActionContext[U8,USize] box) : USize =>
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
    let result = seq_rule.parse(memo, memo.start())?

    match result
    | None => h.fail("sequence did not match")
    | let r: ParseResult[U8,USize] =>
      match r.value()
      | let sum: USize =>
        h.assert_eq[USize](15, sum, "sequence action did not return the correct value")
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
    let literal = ParseLiteral[U8,USize](str, {
      (ctx: ParseActionContext[U8,USize] box) : USize =>
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
    let result = literal.parse(memo, memo.start())?

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
    let memo = ParseState[U8,None](src)?
    let literal = ParseLiteral[U8,None](str)
    let result = literal.parse(memo, memo.start())?

    match result
    | None => h.fail("literal did not match")
    | let result': ParseResult[U8,None] =>
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
