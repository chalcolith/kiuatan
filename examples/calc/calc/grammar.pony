
use k = "kiuatan"

type Var is k.Variable
type Rule is k.Rule[U8, F64]
type Result is k.Result[U8, F64]
type Success is k.Success[U8, F64]
type Failure is k.Failure[U8, F64]
type Lit is k.Literal[U8, F64]
type Sing is k.Single[U8, F64]
type Conj is k.Conj[U8, F64]
type Disj is k.Disj[U8, F64]
type Star is k.Star[U8, F64]
type Neg is k.Neg[U8, F64]
type Bind is k.Bind[U8, F64]

class Grammar
  var _expression: (Rule ref | None) = None
  var _additive: (Rule ref | None) = None
  var _multiplicative: (Rule ref | None) = None
  var _term: (Rule ref | None) = None
  var _float: (Rule | None) = None
  var _integer: (Rule | None) = None
  var _fraction: (Rule | None) = None
  var _exponent: (Rule | None) = None
  var _space: (Rule | None) = None
  var _eof: (Rule | None) = None

  fun ref expression(): Rule ref =>
    match _expression
    | let r: Rule ref =>
      r
    else
      let exp = Rule("Expression")
      _expression = exp

      exp.set_body(Conj([additive(); eof()]))
      exp
    end

  fun ref additive(): Rule ref =>
    match _additive
    | let r: Rule ref =>
      r
    else
      let a = Var
      let o = Var
      let b = Var

      let add = Rule("Additive")
      _additive = add

      add.set_body(Disj(
        [ Conj(
            [ Bind(a, add)
              Bind(o, Conj([ Sing("+-") ; space() ]))
              Bind(b, multiplicative())
            ],
            {(result, values, bindings) =>
              var first: F64 = 0.0
              var op_is_add: Bool = true
              var second: F64 = 0.0

              match try bindings(a)? end
              | (_, let n: F64) =>
                first = n
              end

              match try bindings(o)? end
              | (let s: Success, _) =>
                try
                  if s.start()? == '-' then
                    op_is_add = false
                  end
                end
              end

              match try bindings(b)? end
              | (_, let n: F64) =>
                second = n
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

  fun ref multiplicative(): Rule ref =>
    match _multiplicative
    | let r: Rule ref =>
      r
    else
      let a = Var
      let o = Var
      let b = Var

      let mul = Rule("Multiplicative")
      _multiplicative = mul

      mul.set_body(Disj(
        [ Conj(
            [ Bind(a, mul)
              Bind(o, Conj([ Sing("*/"); space() ]))
              Bind(b, term())
            ],
            {(result, values, bindings) =>
              var first: F64 = 1.0
              var op_is_mul: Bool = true
              var second: F64 = 1.0

              match try bindings(a)? end
              | (_, let n: F64) =>
                first = n
              end

              match try bindings(o)? end
              | (let s: Success, _) =>
                try
                  if s.start()? == '/' then
                    op_is_mul = false
                  end
                end
              end

              match try bindings(b)? end
              | (_, let n: F64) =>
                second = n
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

  fun ref term(): Rule ref =>
    match _term
    | let r: Rule ref =>
      r
    else
      let term' = Rule("Term")
      _term = term'
      term'.set_body(Disj(
        [ Conj(
            [ Conj([ Lit("("); space() ])
              expression()
              Conj([ Lit(")"); space() ])
            ])
          float()
        ]))
      term'
    end

  fun ref float(): Rule =>
    match _float
    | let r: Rule =>
      r
    else
      let i = Var
      let f = Var
      let e = Var

      let float' =
        recover val
          Rule("Float", Conj(
            [ Bind(i, integer())
              Bind(f, Star(fraction(), 0, None, 1))
              Bind(e, Star(exponent(), 0, None, 1))
              space()
            ],
            {(result, subvals, bindings) =>
              var int_num: F64 = 0.0
              var frac_num: F64 = 0.0
              var exp_num: F64 = 1.0

              match try bindings(i)? end
              | (_, let n: F64) =>
                int_num = n
              end

              match try bindings(f)? end
              | (_, let n: F64) =>
                frac_num = n
              end

              match try bindings(e)? end
              | (_, let n: F64) =>
                exp_num = n
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

  fun ref integer(): Rule =>
    match _integer
    | let r: Rule =>
      r
    else
      let integer' =
        recover val
          Rule("Int", Conj(
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


  fun ref fraction(): Rule =>
    match _fraction
    | let r: Rule =>
      r
    else
      let fraction' =
        recover val
          let i = Var

          Rule("Frac",
            Conj(
              [ Lit(".")
                Star(Bind(i, integer()), 0,
                  {(r,_,b) =>
                    var f: F64 = 0.0
                    match try b(i)? end
                    | (let s: Success, let n: F64) =>
                      f = n
                      for _ in s.start.values(s.next) do
                        f = f / 10.0
                      end
                    end
                    (f, b)
                  }, 1)
              ]))
        end
      _fraction = fraction'
      fraction'
    end

  fun ref exponent(): Rule =>
    match _exponent
    | let r: Rule =>
      r
    else
      let exponent' = recover val Rule("Exp", Conj([ Sing("eE"); integer() ])) end
      _exponent = exponent'
      exponent'
    end

  fun ref space(): Rule =>
    match _space
    | let r: Rule =>
      r
    else
      let space' = recover val Rule("WS", Star(Sing(" \t"))) end
      _space = space'
      space'
    end

  fun ref eof(): Rule =>
    match _eof
    | let r: Rule =>
      r
    else
      let eof' = recover val Rule("EOF", Neg(Sing())) end
      _eof = eof'
      eof'
    end
