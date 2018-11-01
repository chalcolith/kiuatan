
use "collections/persistent"
use "itertools"
use "ponytest"
use "promises"
use ".."

class iso _TestRuleAny is UnitTest
  fun name(): String => "Rule_Any"

  fun apply(h: TestHelper) =>
    let rule = recover val Rule[U8]("Any", Single[U8]()) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a']], 0, 1)
        Assert[U8].test_matches(h, rule, true, [['a']; ['b']], 0, 1)
        Assert[U8].test_matches(h, rule, false, [[]], 0, 0)
      ])


class iso _TestRuleAnyClass is UnitTest
  fun name(): String => "Rule_Any_Class"

  fun apply(h: TestHelper) =>
    let rule = recover val Rule[U8]("Any", Single[U8](['a';'b'])) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a']], 0, 1)
        Assert[U8].test_matches(h, rule, true, [['b']], 0, 1)
        Assert[U8].test_matches(h, rule, false, [['x']], 0, 0)
        Assert[U8].test_matches(h, rule, false, [[]], 0, 0)
      ])


class iso _TestRuleLiteralSingle is UnitTest
  fun name(): String => "Rule_Literal_Single"

  fun apply(h: TestHelper) =>
    let rule = recover val Rule[U8]("Literal", Literal[U8]("bar")) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['b'; 'a'; 'r']], 0, 3)
        Assert[U8].test_matches(h, rule, false, [['a'; 'b'; 'a'; 'r']], 0, 0)
        Assert[U8].test_matches(h, rule, true, [['b'; 'a'; 'r'; 'a']], 0, 3)
        Assert[U8].test_matches(h, rule, false, [['b'; 'a']], 0, 0)
      ])


class iso _TestRuleLiteralMulti is UnitTest
  fun name(): String => "Rule_Literal_Multi"

  fun apply(h: TestHelper) =>
    let rule = recover val Rule[U8]("Literal", Literal[U8]("bar")) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a'; 'b']; ['a'; 'r']], 1, 3) ]
    )


class iso _TestRuleConj is UnitTest
  fun name(): String => "Rule_Conj_Valid"

  fun apply(h: TestHelper) =>
    let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
    let cd = recover val Rule[U8]("CD", Literal[U8]("cd")) end
    let ef = recover val Rule[U8]("EF", Literal[U8]("ef")) end
    let rule = recover val Rule[U8]("Conj", Conj[U8]([ab; cd; ef])) end

    Assert[U8].test_promises(h,
      [
        Assert[U8].test_matches(h, rule, true,
          [['a';'b';'c';'d';'e';'f']], 0, 6)
      ])


class iso _TestRuleConjInvalid is UnitTest
  fun name(): String => "Rule_Conj_Invalid"

  fun apply(h: TestHelper) =>
    let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
    let cd = recover val Rule[U8]("CD", Literal[U8]("cd")) end
    let rule = recover val Rule[U8]("Conj", Conj[U8]([ab; cd])) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 4) ]
    )


class iso _TestRuleDisj is UnitTest
  fun name(): String => "Rule_Disj"

  fun apply(h: TestHelper) =>
    let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
    let cd = recover val Rule[U8]("CD", Literal[U8]("cd")) end
    let rule = recover val Rule[U8]("Disj", Disj[U8]([ab; cd])) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b']], 0, 2)
        Assert[U8].test_matches(h, rule, true, [['c';'d']], 0, 2)
        Assert[U8].test_matches(h, rule, false, [[]], 0, 0)
        Assert[U8].test_matches(h, rule, false, [['x';'y']], 0, 0)
      ])


class iso _TestRuleErr is UnitTest
  fun name(): String => "Rule_Err"

  fun apply(h: TestHelper) =>
    let msg = "parse failed"
    let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
    let er = recover val Rule[U8]("ER", Error[U8](msg)) end
    let rule = recover val Rule[U8](name(), Conj[U8]([ab; er])) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, false, [['a';'b';'c']], 0, 3, None, msg)
        Assert[U8].test_matches(h, rule, false, [['x';'y';'z']], 0, 3, None, "")
      ])


  class iso _TestRuleLook is UnitTest
    fun name(): String => "Rule_Look"

    fun apply(h: TestHelper) =>
      let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
      let cd =
        recover val Rule[U8]("CD", Look[U8](Literal[U8]("cd"))) end
      let rule = recover val Rule[U8](name(), Conj[U8]([ab; cd])) end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [['a';'b';'c';'d']], 0, 2)
          Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 0)
        ])


  class iso _TestRuleNeg is UnitTest
    fun name(): String => "Rule_Neg"

    fun apply(h: TestHelper) =>
      let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
      let cd =
        recover val Rule[U8]("CD", Neg[U8](Literal[U8]("cd"))) end
      let rule = recover val Rule[U8](name(), Conj[U8]([ab; cd])) end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [['a';'b';'x';'y']], 0, 2)
          Assert[U8].test_matches(h, rule, false, [['a';'b';'c';'d']], 0, 0)
        ])


  class iso _TestRuleStarZero is UnitTest
    fun name(): String => "Rule_Star_Zero"

    fun apply(h: TestHelper) =>
      let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
      let rule = recover val Rule[U8](name(), Star[U8](ab, 0)) end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [['a';'b']], 0, 2)
          Assert[U8].test_matches(h, rule, true, [['x';'y']], 0, 0)
          Assert[U8].test_matches(h, rule, true,
            [['a';'b';'a';'b';'a';'b';'x';'y']], 0, 6)
        ])


  class iso _TestRuleStarMin is UnitTest
    fun name(): String => "Rule_Star_Min"

    fun apply(h: TestHelper) =>
      let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
      let rule = recover val Rule[U8](name(), Star[U8](ab, 2)) end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b']], 0, 4)
          Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 0)
          Assert[U8].test_matches(h, rule, true,
            [['a';'b';'a';'b';'a';'b';'x';'y']], 0, 6)
        ])


  class iso _TestRuleStarMax is UnitTest
    fun name(): String => "Rule_Star_Max"

    fun apply(h: TestHelper) =>
      let ab = recover val Rule[U8]("AB", Literal[U8]("ab")) end
      let rule =
        recover val Rule[U8](name(), Star[U8](ab, 2, None, 4)) end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b']], 0, 4)
          Assert[U8].test_matches(h, rule, true,
            [['a';'b';'a';'b';'a';'b']], 0, 6)
          Assert[U8].test_matches(h, rule, true,
            [['a';'b';'a';'b';'a';'b';'a';'b']], 0, 8)
          Assert[U8].test_matches(h, rule, false, [['a';'b']], 0, 0)
          Assert[U8].test_matches(h, rule, false, [['x';'y';'a';'b']], 0, 0)
        ])


  class iso _TestRuleForwardDeclare is UnitTest
    fun name(): String => "Rule_ForwardDeclare"

    fun apply(h: TestHelper) =>
      let rule: Rule[U8] val =
        recover
          let r: Rule[U8] ref = Rule[U8](name(), None)
          let ab = Rule[U8]("AB", Literal[U8]("ab"))
          let cd = Rule[U8]("CD", Literal[U8]("cd"))
          let disj = Disj[U8]([r; cd])
          let body = Conj[U8]([ab; disj])
          r.set_body(body)
          r
        end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [ "ababcd" ], 0, 6)
          Assert[U8].test_matches(h, rule, false, [ "cd" ], 0, 0)
        ])


  class iso _TestRuleLRImmediate is UnitTest
    fun name(): String => "Rule_LR_Immediate"

    fun apply(h: TestHelper) =>
      // Add <- Add Op Num | Num
      // Op <- [+-]
      // Num <- [0-9]+
      let rule: Rule[U8] val =
        recover
          let add = Rule[U8](name(), None)
          let num = Rule[U8]("Num", Star[U8](Single[U8]("0123456789"), 1))
          let op = Rule[U8]("Op", Single[U8]("+-"))
          let body = Disj[U8]([Conj[U8]([add; op; num]); num])
          add.set_body(body)
          add
        end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [ "123" ], 0, 3)
          Assert[U8].test_matches(h, rule, true, [ "123+456" ], 0, 7)
          Assert[U8].test_matches(h, rule, false, [ "+" ], 0, 0)
          Assert[U8].test_matches(h, rule, false, [ "" ], 0, 0)
        ])


  class iso _TestRuleLRLeftAssoc is UnitTest
    fun name(): String => "Rule_LR_LeftAssoc"

    fun apply(h: TestHelper) =>
      // Add <- Add Op Num | Num
      // Op <- [+-]
      // Num <- [0-9]+
      let rule: Rule[U8] val =
        recover
          let add = Rule[U8](name(), None)
          let num = Rule[U8]("Num", Star[U8](Single[U8]("0123456789"), 1))
          let op = Rule[U8]("Op", Single[U8]("+-"))
          let body = Disj[U8]([Conj[U8]([add; op; num]); num])
          add.set_body(body)
          add
        end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [ "1+2+3" ], 0, 5) ])


  class iso _TestRuleLRIndirect is UnitTest
    fun name(): String => "Rule_LR_Indirect"

    fun apply(h: TestHelper) =>
      // A <- B 'z' | 'x'
      // B <- A 'y'
      let rule: Rule[U8] val =
        recover
          let a = Rule[U8]("A", None)
          let b = Rule[U8]("B", Conj[U8]([ a; Literal[U8]("y") ]))
          a.set_body(Disj[U8](
            [ Conj[U8]([ b; Literal[U8]("z") ])
              Literal[U8]("x")
            ]))
          a
        end

      Assert[U8].test_promises(h,
        [ Assert[U8].test_matches(h, rule, true, [ "xyz" ], 0, 3)
        ])


  class iso _TestRuleVariableBind is UnitTest
    fun name(): String => "Rule_Variable_Bind"

    fun apply(h: TestHelper) =>
      let x = Variable
      let y = Variable
      let rule =
        recover val
          Rule[U8, USize]("Rule", Conj[U8, USize](
            [ Bind[U8, USize](x, Literal[U8, USize]("x",
                {(_,_,b) =>
                  (USize(1),b)
                }))
              Bind[U8, USize](y, Literal[U8, USize]("y",
                {(_,_,b) =>
                  (USize(2),b)
                }))
            ],
            {(result, vals, bindings) =>
              var vx: USize = 0
              var vy: USize = 0

              match try bindings(x)? end
              | (_, let vx': USize) =>
                vx = vx'
              else
                return (None, bindings)
              end

              match try bindings(y)? end
              | (_, let vy': USize) =>
                vy = vy'
              else
                return (None, bindings)
              end

              let vv: (USize | None) = vx + vy
              (vv, bindings)
            }))
        end

      Assert[U8, USize].test_promises(h,
        [ Assert[U8, USize].test_matches(h, rule, true, [ "xy" ], 0, 2, 3)
        ])


class iso _TestRuleCondition is UnitTest
  fun name(): String => "Rule_Condition"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        Rule[U8]("Condition", Cond[U8](
          Disj[U8]([ Literal[U8]("x"); Literal[U8]("y") ]),
          {(success) =>
            if Assert[U8].iter_eq("y".values(),
              success.start.values(success.next))
            then
              (true, None)
            else
              (false, "condition failed")
            end
          }
        ))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [ "y" ], 0, 1)
        Assert[U8].test_matches(h, rule, false, [ "x" ], 0, 1)
      ])
