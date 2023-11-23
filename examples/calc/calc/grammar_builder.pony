
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
  let expression: NamedRule = NamedRule("Expression")
  let additive: NamedRule = NamedRule("Additive")
  let multiplicative: NamedRule = NamedRule("Multiplicative")
  let term: NamedRule = NamedRule("Term")
  let float: NamedRule = NamedRule("Float")
  let integer: NamedRule = NamedRule("Integer")
  let fraction: NamedRule = NamedRule("Fraction")
  let exponent: NamedRule = NamedRule("Exponent")
  let lpar: NamedRule = NamedRule("LeftParen")
  let rpar: NamedRule = NamedRule("RightParen")
  let add_op: NamedRule = NamedRule("OpAdd")
  let mul_op: NamedRule = NamedRule("OpMul")
  let space: NamedRule = NamedRule("Space")
  let eof: NamedRule = NamedRule("EOF")

  new create() =>
    _gen_expression()
    _gen_additive()
    _gen_multiplicative()
    _gen_term()
    _gen_float()
    _gen_integer()
    _gen_fraction()
    _gen_exponent()
    _gen_lex()

  fun ref _gen_expression() =>
    expression.set_body(Conj([additive; eof]))

  fun ref _gen_additive() =>
    let a = Var("a")
    let o = Var("o")
    let b = Var("b")

    additive.set_body(
      Disj(
        [ Conj(
            [ Bind(a, additive)
              Bind(o, add_op)
              Bind(b, multiplicative) ],
            {(_, result, values, bindings) =>
              var first: F64 = 0.0
              var op_is_add: Bool = true
              var second: F64 = 0.0

              try
                first = bindings.values(a, result)?(0)?
              end

              try
                if bindings(o, result)?._1.start()? == '-' then
                  op_is_add = false
                end
              end

              try
                second = bindings.values(b, result)?(0)?
              end

              let sum: (F64 | None) =
                if op_is_add then
                  first + second
                else
                  first - second
                end
              (sum, bindings)
            })
          Bind(b, multiplicative)
        ]))

  fun ref _gen_multiplicative() =>
    let a = Var("a")
    let o = Var("o")
    let b = Var("b")

    multiplicative.set_body(
      Disj(
        [ Conj(
            [ Bind(a, multiplicative)
              Bind(o, mul_op)
              Bind(b, term) ],
            {(_, result, values, bindings) =>
              var first: F64 = 1.0
              var op_is_mul: Bool = true
              var second: F64 = 1.0

              try
                first = bindings.values(a, result)?(0)?
              end

              try
                if bindings(o, result)?._1.start()? == '/' then
                  op_is_mul = false
                end
              end

              try
                second = bindings.values(b, result)?(0)?
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
          Bind(b, term)
        ]))

  fun ref _gen_term() =>
    term.set_body(
      Disj(
        [ Conj([ lpar; additive; rpar])
          float
        ]))

  fun ref _gen_float() =>
    let i = Var("i")
    let f = Var("f")
    let e = Var("e")

    float.set_body(
      Conj(
        [ Bind(i, integer)
          Bind(f, Star(fraction where min' = 0, max' = 1))
          Bind(e, Star(exponent where min' = 0, max' = 1))
          space ],
        {(_, result, values, bindings) =>
          var int_num: F64 = 0.0
          var frac_num: F64 = 0.0
          var exp_num: F64 = 1.0

          try
            int_num = bindings.values(i, result)?(0)?
          end

          try
            frac_num = bindings.values(f, result)?(0)?
          end

          try
            exp_num = bindings.values(e, result)?(0)?
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

  fun ref _gen_integer() =>
    integer.set_body(
      Conj(
        [ Star(Sing("-+") where min' = 0, max' = 1)
          Star(Sing("0123456789"), 1) ],
        {(_,r,_,b) =>
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
        }))

  fun ref _gen_fraction() =>
    let i = Var("i")

    fraction.set_body(
      Conj(
        [ Lit(".")
          Star(
            Bind(i, integer),
            0,
            {(_,r,_,b) =>
              var f: F64 = 0.0

              try
                match b(i, r)?
                | (let s: Success, let ns: ReadSeq[F64] val) =>
                  f = ns(0)?
                  for _ in s.start.values(s.next) do
                    f = f / 10.0
                  end
                end
              end

              (f, b)
            },
            1)
        ]))

  fun ref _gen_exponent() =>
    exponent.set_body(Conj([ Sing("eE"); integer ]))

  fun ref _gen_lex() =>
    lpar.set_body(Conj([ Lit("("); space ]))
    rpar.set_body(Conj([ Lit(")"); space ]))
    add_op.set_body(Conj([ Sing("+-"); space ]))
    mul_op.set_body(Conj([ Sing("*/"); space ]))
    space.set_body(Star(Sing(" \t")))
    eof.set_body(Neg(Sing()))
