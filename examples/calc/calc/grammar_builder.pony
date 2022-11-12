
use k = "../../../kiuatan"

type Var is k.Variable
type NamedRule is k.NamedRule[U8, None, F64]
type Result is k.Result[U8, None, F64]
type Success is k.Success[U8, None, F64]
type Failure is k.Failure[U8, None, F64]
type Lit is k.Literal[U8, None, F64]
type Sing is k.Single[U8, None, F64]
type Conj is k.Conj[U8, None, F64]
type Disj is k.Disj[U8, None, F64]
type Star is k.Star[U8, None, F64]
type Neg is k.Neg[U8, None, F64]
type Bind is k.Bind[U8, None, F64]

class GrammarBuilder
  """
  Builds a Kiuatan PEG grammar for simple arithmetic expressions, including
  semantic actions that construct the resulting values.

  Note that the grammar is left-recursive, which Kiuatan handles just fine.

  ```
  Expression <- Additive EOF
  Additive <- Additive ADD_OP Multiplicative / Multiplicative
  Multiplicative <- Multiplicative MUL_OP Term / Term
  Term <- LPAR Additive RPAR / Float
  Float <- Integer Fraction? Exponent? Space
  Integer <- [-+]? [0-9]+
  Fraction <- '.' Integer?
  Exponent <- [eE] Integer
  LPAR <- '(' Space
  RPAR <- ')' Space
  ADD_OP <- [-+] Space
  MUL_OP <- [*/] Space
  Space <- [ \t]*
  EOF <- ~.
  ```
  """
  var _expression: (NamedRule ref | None) = None
  var _additive: (NamedRule ref | None) = None
  var _multiplicative: (NamedRule ref | None) = None
  var _term: (NamedRule ref | None) = None
  var _float: (NamedRule | None) = None
  var _integer: (NamedRule | None) = None
  var _fraction: (NamedRule | None) = None
  var _exponent: (NamedRule | None) = None
  var _lpar: (NamedRule | None) = None
  var _rpar: (NamedRule | None) = None
  var _add_op: (NamedRule | None) = None
  var _mul_op: (NamedRule | None) = None
  var _space: (NamedRule | None) = None
  var _eof: (NamedRule | None) = None

  fun ref expression(): NamedRule ref =>
    match _expression
    | let r: NamedRule ref =>
      r
    else
      let exp = NamedRule("Expression")
      _expression = exp

      exp.set_body(Conj([additive(); eof()]))
      exp
    end

  fun ref additive(): NamedRule ref =>
    match _additive
    | let r: NamedRule ref =>
      r
    else
      let a = Var("a")
      let o = Var("o")
      let b = Var("b")

      let add = NamedRule("Additive")
      _additive = add

      add.set_body(Disj(
        [ Conj(
            [ Bind(a, add)
              Bind(o, add_op())
              Bind(b, multiplicative())
            ],
            {(result, values, bindings) =>
              var first: F64 = 0.0
              var op_is_add: Bool = true
              var second: F64 = 0.0

              try
                first = bindings(a)?._2(0)?
              end

              try
                if bindings(o)?._1.start()? == '-' then
                  op_is_add = false
                end
              end

              try
                second = bindings(b)?._2(0)?
              end

              let sum: (F64 | None) =
                if op_is_add then
                  first + second
                else
                  first - second
                end
              (sum, bindings)
            })
          Bind(b, multiplicative())
        ]))
      add
    end

  fun ref multiplicative(): NamedRule ref =>
    match _multiplicative
    | let r: NamedRule ref =>
      r
    else
      let a = Var("a")
      let o = Var("o")
      let b = Var("b")

      let mul = NamedRule("Multiplicative")
      _multiplicative = mul

      mul.set_body(Disj(
        [ Conj(
            [ Bind(a, mul)
              Bind(o, mul_op())
              Bind(b, term())
            ],
            {(result, values, bindings) =>
              var first: F64 = 1.0
              var op_is_mul: Bool = true
              var second: F64 = 1.0

              try
                first = bindings(a)?._2(0)?
              end

              try
                if bindings(o)?._1.start()? == '/' then
                  op_is_mul = false
                end
              end

              try
                second = bindings(b)?._2(0)?
              end

              let prod: (F64 | None) =
                if op_is_mul then
                  first * second
                else
                  if second > 0.0 then
                    first / second
                  else
                    0.0
                  end
                end
              (prod, bindings)
            })
          Bind(b, term())
        ]))
      mul
    end

  fun ref term(): NamedRule ref =>
    match _term
    | let r: NamedRule ref =>
      r
    else
      let term' = NamedRule("Term")
      _term = term'
      term'.set_body(Disj(
        [ Conj(
            [ lpar()
              additive()
              rpar()
            ])
          float()
        ]))
      term'
    end

  fun ref lpar(): NamedRule =>
    match _lpar
    | let r: NamedRule =>
      r
    else
      let lpar' = recover val NamedRule("LPAR", Conj([ Lit("("); space() ])) end
      _lpar = lpar'
      lpar'
    end

  fun ref rpar(): NamedRule =>
    match _rpar
    | let r: NamedRule =>
      r
    else
      let rpar' = recover val NamedRule("RPAR", Conj([ Lit(")"); space() ])) end
      _rpar = rpar'
      rpar'
    end

  fun ref add_op(): NamedRule =>
    match _add_op
    | let r: NamedRule =>
      r
    else
      let add_op' =
        recover val NamedRule("ADDOP", Conj([ Sing("+-"); space() ])) end
      _add_op = add_op'
      add_op'
    end

  fun ref mul_op(): NamedRule =>
    match _mul_op
    | let r: NamedRule =>
      r
    else
      let mul_op' =
        recover val NamedRule("MULOP", Conj([ Sing("*/"); space() ])) end
      _mul_op = mul_op'
      mul_op'
    end

  fun ref float(): NamedRule =>
    match _float
    | let r: NamedRule =>
      r
    else
      let i = Var("i")
      let f = Var("f")
      let e = Var("e")

      let float' =
        recover val
          NamedRule("Float", Conj(
            [ Bind(i, integer())
              Bind(f, Star(fraction(), 0, None, 1))
              Bind(e, Star(exponent(), 0, None, 1))
              space()
            ],
            {(result, subvals, bindings) =>
              var int_num: F64 = 0.0
              var frac_num: F64 = 0.0
              var exp_num: F64 = 1.0

              try
                int_num = bindings(i)?._2(0)?
              end

              try
                frac_num = bindings(f)?._2(0)?
              end

              try
                exp_num = bindings(e)?._2(0)?
              end

              let n =
                if int_num < 0.0 then
                  int_num - frac_num
                else
                  int_num + frac_num
                end

              if exp_num != 1.0 then
                (n * F64(10).pow(exp_num), bindings)
              else
                (n, bindings)
              end
            }))
        end
      _float = float'
      float'
    end

  fun ref integer(): NamedRule =>
    match _integer
    | let r: NamedRule =>
      r
    else
      let integer' =
        recover val
          NamedRule("Int", Conj(
            [ Star(Sing("-+"), 0, None, 1)
              Star(Sing("0123456789"), 1)
            ]),
            {(r,_,b) =>
              var n: F64 = 0.0
              try
                var start = r.start
                var ss = start()?

                var sign: F64 = 1.0
                if (ss == '+') or (ss == '-') then
                  if ss == '-' then
                    sign = -1.0
                  end
                  start = start.next()
                end

                for ch in start.values(r.next) do
                  n = (n * 10.0) + (ch - '0').f64()
                end
                n = n * sign
              end
              (n, b)
            })
        end
      _integer = integer'
      integer'
    end


  fun ref fraction(): NamedRule =>
    match _fraction
    | let r: NamedRule =>
      r
    else
      let fraction' =
        recover val
          let i = Var("i")

          NamedRule("Frac",
            Conj(
              [ Lit(".")
                Star(Bind(i, integer()), 0,
                  {(r,_,b) =>
                    var f: F64 = 0.0

                    try
                      match b(i)?
                      | (let s: Success, let ns: ReadSeq[F64] val) =>
                        f = ns(0)?
                        for _ in s.start.values(s.next) do
                          f = f / 10.0
                        end
                      end
                    end

                    (f, b)
                  }, 1)
              ]))
        end
      _fraction = fraction'
      fraction'
    end

  fun ref exponent(): NamedRule =>
    match _exponent
    | let r: NamedRule =>
      r
    else
      let exponent' = recover val NamedRule("Exp", Conj([ Sing("eE"); integer() ])) end
      _exponent = exponent'
      exponent'
    end

  fun ref space(): NamedRule =>
    match _space
    | let r: NamedRule =>
      r
    else
      let space' = recover val NamedRule("WS", Star(Sing(" \t"))) end
      _space = space'
      space'
    end

  fun ref eof(): NamedRule =>
    match _eof
    | let r: NamedRule =>
      r
    else
      let eof' = recover val NamedRule("EOF", Neg(Sing())) end
      _eof = eof'
      eof'
    end
