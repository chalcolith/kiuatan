use "collections/persistent"
use "itertools"
use "pony_test"
use "promises"

use ".."

class iso _TestRuleAny is UnitTest
  fun name(): String => "Rule_Any"

  fun apply(h: TestHelper) =>
    let rule = recover val NamedRule[U8]("Any", Single[U8]) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a']], 0, 1)
        Assert[U8].test_matches(h, rule, true, [['a']; ['b']], 0, 1)
        Assert[U8].test_matches(h, rule, false, [[]], 0, 0)
      ])

class iso _TestRuleAnyClass is UnitTest
  fun name(): String => "Rule_Any_Class"

  fun apply(h: TestHelper) =>
    let rule = recover val NamedRule[U8]("Any", Single[U8](['a';'b'])) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a']], 0, 1)
        Assert[U8].test_matches(h, rule, true, [['b']], 0, 1)
        Assert[U8].test_matches(h, rule, false, [['x']], 0, 0)
        Assert[U8].test_matches(h, rule, false, [[]], 0, 0)
      ])

class iso _TestRuleLiteralSingle is UnitTest
  fun name(): String => "Rule_Literal_Single"

  fun apply(h: TestHelper) =>
    let rule = recover val NamedRule[U8]("Literal", Literal[U8]("bar")) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['b'; 'a'; 'r']], 0, 3)
        Assert[U8].test_matches(h, rule, false, [['a'; 'b'; 'a'; 'r']], 0, 0)
        Assert[U8].test_matches(h, rule, true, [['b'; 'a'; 'r'; 'a']], 0, 3)
        Assert[U8].test_matches(h, rule, false, [['b'; 'a']], 0, 0)
      ])

class iso _TestRuleLiteralMulti is UnitTest
  fun name(): String => "Rule_Literal_Multi"

  fun apply(h: TestHelper) =>
    let rule = recover val NamedRule[U8]("Literal", Literal[U8]("bar")) end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a'; 'b']; ['a'; 'r']], 1, 3) ]
    )

class iso _TestRuleConj is UnitTest
  fun name(): String => "Rule_Conj_Valid"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8]("Conj",
          Conj[U8]([
            NamedRule[U8]("AB", Literal[U8]("ab"))
            NamedRule[U8]("CD", Literal[U8]("cd"))
            NamedRule[U8]("EF", Literal[U8]("ef"))
          ]))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b';'c';'d';'e';'f']], 0, 6) ])

class iso _TestRuleConjInvalid is UnitTest
  fun name(): String => "Rule_Conj_Invalid"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let cd = NamedRule[U8]("CD", Literal[U8]("cd"))
        NamedRule[U8]("Conj", Conj[U8]([ab; cd]))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 4) ]
    )

class iso _TestRuleDisj is UnitTest
  fun name(): String => "Rule_Disj"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let cd = NamedRule[U8]("CD", Literal[U8]("cd"))
        NamedRule[U8]("Disj", Disj[U8]([ab; cd]))
      end

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

    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let er = NamedRule[U8]("ER", Error[U8](msg))

        NamedRule[U8](
          name(),
          Conj[U8]([
            ab
            Disj[U8]([
              Literal[U8]("mn")
              er
            ])
          ]))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, false, [['a';'b';'c']], 0, 3, None, None, msg)
        Assert[U8].test_matches(h, rule, false, [['x';'y';'z']], 0, 3, None, None, "")
      ])

class iso _TestRuleLook is UnitTest
  fun name(): String => "Rule_Look"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let cd = NamedRule[U8]("CD", Look[U8](Literal[U8]("cd")))
        NamedRule[U8](name(), Conj[U8]([ab; cd]))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b';'c';'d']], 0, 2)
        Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 0)
      ])

class iso _TestRuleNeg is UnitTest
  fun name(): String => "Rule_Neg"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let cd = NamedRule[U8]("CD", Neg[U8](Literal[U8]("cd")))
        NamedRule[U8](name(), Conj[U8]([ab; cd]))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b';'x';'y']], 0, 2)
        Assert[U8].test_matches(h, rule, false, [['a';'b';'c';'d']], 0, 0)
      ])

class iso _TestRuleStarZero is UnitTest
  fun name(): String => "Rule_Star_Zero"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        NamedRule[U8](name(), Star[U8](ab, 0))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b']], 0, 2)
        Assert[U8].test_matches(h, rule, true, [['x';'y']], 0, 0)
        Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b';'a';'b';'x';'y']], 0, 6)
      ])

class iso _TestRuleStarMin is UnitTest
  fun name(): String => "Rule_Star_Min"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        NamedRule[U8](name(), Star[U8](ab, 2))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b']], 0, 4)
        Assert[U8].test_matches(h, rule, false, [['a';'b';'x';'y']], 0, 0)
        Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b';'a';'b';'x';'y']], 0, 6)
      ])

class iso _TestRuleStarMax is UnitTest
  fun name(): String => "Rule_Star_Max"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        NamedRule[U8](name(), Star[U8](ab, 2, None, 4))
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [['a';'b';'a';'b']], 0, 4)
        Assert[U8].test_matches(h, rule, true,
          [['a';'b';'a';'b';'a';'b']], 0, 6)
        Assert[U8].test_matches(h, rule, true,
          [['a';'b';'a';'b';'a';'b';'a';'b']], 0, 8)
        Assert[U8].test_matches(h, rule, false, [['a';'b']], 0, 0)
        Assert[U8].test_matches(h, rule, false, [['x';'y';'a';'b']], 0, 0)
      ])

class iso _TestRuleStarChildren is UnitTest
  fun name(): String => "Rule_Star_Children"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8, None, USize]("Dots",
          Star[U8, None, USize](
            Single[U8, None, USize](".",
              {(_, _, b) =>
                (USize(1), b)
              }),
            1),
          {(_, c, b) =>
            (c.size(), b)
          })
      end

    Assert[U8, None, USize].test_promises(h, [
      Assert[U8, None, USize].test_matches(
        h,
        rule,
        true,
        [[ '.'; '.' ]],
        0,
        2,
        None,
        2)
    ])

class iso _TestRuleForwardDeclare is UnitTest
  fun name(): String => "Rule_ForwardDeclare"

  fun apply(h: TestHelper) =>
    let rule: NamedRule[U8] val =
      recover
        let r: NamedRule[U8] ref = NamedRule[U8](name())
        let ab = NamedRule[U8]("AB", Literal[U8]("ab"))
        let cd = NamedRule[U8]("CD", Literal[U8]("cd"))
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
    let rule: NamedRule[U8] val =
      recover
        let add = NamedRule[U8]("Add")
        let num = NamedRule[U8]("Num", Star[U8](Single[U8]("0123456789"), 1))
        let op = NamedRule[U8]("Op", Single[U8]("+-"))
        let body = Disj[U8]([
          Conj[U8]([
            add
            op
            num
          ])
          num])
        add.set_body(body)
        add
      end

    Assert[U8].test_promises(h,
      [ //Assert[U8].test_matches(h, rule, true, [ "123" ], 0, 3)
        Assert[U8].test_matches(h, rule, true, [ "123+456" ], 0, 7)
        //Assert[U8].test_matches(h, rule, false, [ "+" ], 0, 0)
        //Assert[U8].test_matches(h, rule, false, [ "" ], 0, 0)
      ])

class iso _TestRuleLRLeftAssoc is UnitTest
  fun name(): String => "Rule_LR_LeftAssoc"

  fun apply(h: TestHelper) =>
    // Add <- Add Op Num | Num
    // Op <- [+-]
    // Num <- [0-9]+
    let rule: NamedRule[U8] val =
      recover
        let add = NamedRule[U8](name())
        let num = NamedRule[U8]("Num", Star[U8](Single[U8]("0123456789"), 1))
        let op = NamedRule[U8]("Op", Single[U8]("+-"))
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
    // B <- A D C
    // C <- 'y'

    // D <- E 'n' | 'l'
    // E <- D 'm'

    let rule: NamedRule[U8] val =
      recover
        let d = NamedRule[U8]("D")
        let e = NamedRule[U8]("E", Conj[U8]([ d; Literal[U8]("m")]))
        d.set_body(
          Disj[U8]([
            Conj[U8]([ e; Literal[U8]("n")])
            Literal[U8]("l")
          ]))

        let a = NamedRule[U8]("A")
        let c = NamedRule[U8]("C", Literal[U8]("y"))
        let b = NamedRule[U8]("B", Conj[U8]([ a; d; c ]))
        a.set_body(
          Disj[U8]([
            Conj[U8]([ b; Literal[U8]("z") ])
            Literal[U8]("x")
          ]))
        a
      end

    Assert[U8].test_promises(h,
      [ Assert[U8].test_matches(h, rule, true, [ "xlmnyz" ], 0, 6)
      ])

class iso _TestRuleVariableBind is UnitTest
  fun name(): String => "Rule_Variable_Bind"

  fun apply(h: TestHelper) =>
    let x = Variable("x")
    let y = Variable("y")

    let rule =
      recover val
        NamedRule[U8, None, USize]("Rule", Conj[U8, None, USize](
          [ Bind[U8, None, USize](x, Literal[U8, None, USize]("x",
              {(_,_,b) =>
                (USize(1),b)
              }))
            Bind[U8, None, USize](y, Literal[U8, None, USize]("y",
              {(_,_,b) =>
                (USize(2),b)
              }))
          ],
          {(result, child_values, bindings) =>
            var vx: USize = 0
            var vy: USize = 0

            try
              vx = bindings.values(x, result)?(0)?
            else
              return (None, bindings)
            end

            try
              vy = bindings.values(y, result)?(0)?
            else
              return (None, bindings)
            end

            let vv: (USize | None) = vx + vy
            (vv, bindings)
          }))
      end

    Assert[U8, None, USize].test_promises(h,
      [ Assert[U8, None, USize].test_matches(h, rule, true, [ "xy" ], 0, 2, None, 3)
      ])

class iso _TestRuleCondition is UnitTest
  fun name(): String => "Rule_Condition"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8]("Condition", Cond[U8](
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

class iso _TestRuleData is UnitTest
  fun name(): String => "Rule_Data"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        NamedRule[U8, String, String]("WithData",
          Literal[U8, String, String]("x",
            {(s, _, b) =>
              let str =
                recover
                  let str': String ref = String
                  for ch in s.start.values(s.next) do
                    str'.push(ch)
                  end
                  str'.>append(s.data)
                end
              (str, b)
            }))
      end

    Assert[U8, String, String].test_promises(h,
      [ Assert[U8, String, String].test_matches(h, rule, true, [ "x" ], 0, 1, "y", "xy")
        Assert[U8, String, String].test_matches(h, rule, false, [ "y" ], 0, 1, "y")
      ])

class iso _TestRuleBindStar is UnitTest
  fun name(): String => "Rule_Bind_Star"

  fun apply(h: TestHelper) =>
    let rule =
      recover val
        let v = Variable("v")
        NamedRule[U8,None,USize]("BindStar",
          Bind[U8,None,USize](v,
            Star[U8,None,USize](
              Single[U8,None,USize]("a",
                {(r,_,b) => (USize(123), b) }))),
          {(r,_,b) =>
            let n: USize =
              try
                let values = b.values(v, r)?
                values.size()
              else
                0
              end
            (n, b)
          })
      end

    Assert[U8, None, USize].test_promises(h, [
      Assert[U8, None, USize].test_matches(h, rule, true, [ "aaa" ], 0, 3, None, 3)
    ])

class _TestRuleBindRecursive is UnitTest
  fun name(): String => "Rule_Bind_Recursive"

  fun apply(h: TestHelper) =>
    let int_rule =
      recover val
        NamedRule[U8,None,String]("Int",
          Star[U8,None,String](Single[U8,None,String]("0123456789")),
          {(r,_,b) =>
            let str = recover val String .> concat(r.start.values(r.next)) end
            (str, b)
          })
      end

    let comma_rule =
      recover val
        let lhs = Variable("lhs")
        let rhs = Variable("rhs")
        let comma_rule' = NamedRule[U8,None,String]("Comma")
        comma_rule'.set_body(
          Conj[U8,None,String](
            [ Bind[U8,None,String](lhs, int_rule)
              Star[U8,None,String](
                Conj[U8,None,String](
                  [ Literal[U8,None,String](",")
                    Bind[U8,None,String](rhs, comma_rule') ])) ]),
          {(r,_,b) =>
            let lhs' = try b.values(lhs, r)?(0)? else "?" end
            let rhs' = try b.values(rhs, r)?(0)? else "?" end
            (recover val lhs' + "," + rhs' end, b)
          })
        comma_rule'
      end

    Assert[U8,None,String].test_promises(h,
      [ Assert[U8,None,String].test_matches(
          h, comma_rule, true, [ "20,10" ], 0, 5, None, "20,10,?") ])
