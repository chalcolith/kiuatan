
class _Calculator
  """
  An example of very simple expression parser for the following grammar:

  ```
  Exp = Add
  Add = Add WS [+-] WS Mul
      | Mul
  Mul = Mul WS [*/] WS Num
      | Num
  Num = '(' WS Exp WS ')' WS
      | [0-9]+ WS
  WS = [ \t]*
  ```
  """

  let _top: ParseRule[U8,ISize]

  new create() =>
    // We pre-declare the Exp rule so we can use it later for recursion.
    let exp = RuleSequence[U8,ISize](Array[ParseRule[U8,ISize]], "Exp")

    // A simple whitespace rule: 0 or more repeats of space or tab.
    let ws =
      RuleRepeat[U8,ISize](
        RuleClass[U8,ISize].from_iter(" \t".values()),
        None,
        0)

    // A number can be either an expression in parentheses, or a string
    // of digits.
    let num =
      RuleChoice[U8,ISize](
        [ RuleSequence[U8,ISize](
            [ RuleLiteral[U8,ISize]("(")
              ws
              exp
              ws
              RuleLiteral[U8,ISize](")")
              ws
            ])
          RuleSequence[U8,ISize](
            [ RuleRepeat[U8,ISize](
                RuleClass[U8,ISize].from_iter("0123456789".values()),
                // A semantic action that converts the string of digits to a
                // decimal number.
                {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
                  var num: ISize = 0
                  for ch in ctx.inputs().values() do
                    num = (num * 10) + (ch.isize() - '0')
                  end
                  num
                },
                1)
              ws
            ])
        ],
        "Num")

    // A multiplicative expression can be a multiplicative expression
    // then a * or /, then a number; or a number.
    let mul = RuleChoice[U8,ISize](Array[ParseRule[U8,ISize]], "Mul")
    mul.push(
      RuleSequence[U8,ISize](
        [ mul
          ws
          RuleClass[U8,ISize].from_iter("*/".values())
          ws
          num ],
        "Mul",
        // A semantic action that multiplies or divides the operands.
        {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
          try
            let a = ctx.values(0)? as ISize
            let b = ctx.values(4)? as ISize

            let str = ctx.results(2)?.inputs()
            if str(0)? == '*' then
              a * b
            else
              a / b
            end
          end
        }))
    mul.push(num)

    // An additive expression can be an additive expression then a + or -,
    // then a multiplicative expression; or a number.
    let add = RuleChoice[U8,ISize](Array[ParseRule[U8,ISize]], "Add")
    add.push(
      RuleSequence[U8,ISize](
        [ add
          ws
          RuleClass[U8,ISize].from_iter("+-".values())
          ws
          mul ],
        "Add",
        {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
          try
            let a = ctx.values(0)? as ISize
            let b = ctx.values(4)? as ISize

            let str = ctx.results(2)?.inputs()
            if str(0)? == '+' then
              a + b
            else
              a - b
            end
          end
        }))
    add.push(mul)

    exp.push(add)
    _top = exp

  fun apply(): this->ParseRule[U8,ISize] =>
    _top
