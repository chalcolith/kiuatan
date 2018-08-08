
use k = "kiuatan"

type Rule is k.Rule[U8, F64]
type Lit is k.Literal[U8, F64]
type Sing is k.Single[U8, F64]
type Conj is k.Conj[U8, F64]
type Star is k.Star[U8, F64]
type Bind is k.Bind[U8, F64]

primitive Grammar
  fun float(): Rule =>
    let int = integer()
    let frac = fraction(int)
    let exp = exponent(int)

    let i = k.Variable
    let f = k.Variable
    let e = k.Variable

    recover val
      Rule("Float", Conj(
        [ Bind(i, int)
          Bind(f, frac)
          Bind(e, exp)
        ],
        {(result, subvals, bindings) =>
          try
            var int_num: F64 = 0.0
            var frac_num: F64 = 0.0
            var exp_num: F64 = 1.0

            match bindings(i)?
            | (_, let n: F64) =>
              int_num = n
            end

            match bindings(f)?
            | (_, let n: F64) =>
              frac_num = n
            end

            match bindings(e)?
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
          else
            (None, bindings)
          end
        }))
    end

  fun integer(): Rule =>
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
          end
          (n, b)
        })
    end


  fun fraction(int: Rule): Rule =>
    recover val
      Rule("Frac",
        Star(Conj(
          [ Lit(".")
            Star(int, 0, {(r,_,b) =>
              var n: F64 = 0.0
              var m: F64 = 0.1
              for ch in r.start.values(r.next) do
                n = n + ((ch - '0').f64() * m)
                m = m * 0.1
              end
              (n,b)
            }, 1)
          ])))
    end

  fun exponent(int: Rule): Rule =>
    recover val
      Rule("Exp", Star(Conj( [ Sing("eE"); int ]), 0, None, 1))
    end
