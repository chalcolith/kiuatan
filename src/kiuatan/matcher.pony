interface RuleBuilder[T, R]
  """
  Object algebra for grammar rules.
  """
  fun term(t: Seq[T]): R
  fun seq(s: Seq[R]): R
  fun disj(s: Seq[R]): R
  fun ques(r: R): R
  fun star(r: R): R
  fun plus(r: R): R

class RuleResult[T]
  let _src: MatchSource[T]
  let _start: MatchSourceLoc[T]
  let _next: MatchSourceLoc[T]
  let _rule: GrammarRule[T]
  let _children: Array[RuleResult[T]]

  new create(src: MatchSource[T], start: MatchSourceLoc[T], next: MatchSourceLoc[T],
             rule: GrammarRule[T], children: Array[RuleResult[T]]) =>
    _src = src
    _start = start
    _next = next
    _rule = rule
    _children = children

  fun src(): MatchSource[T] => _src
  fun start(): MatchSource[T] => _start
  fun next(): MatchSource[T] => _next
  fun rule(): GrammarRule[T] => _rule
  fun children(): Array[RuleResult[T]]

interface GrammarRule[T]
  fun 
  fun parse(src: MatchSource[T], start: MatchSourceLoc[T]): (RuleResult[T] | None)

interface Matcher[T]
  fun term(t: Seq[T]): RuleResult[T] =>
    recover
      object
        let text: Seq[T] = t
        fun parse(src: MatchSource[T], start: MatchSourceLoc[T]): (RuleResult[T] | None) =>
          let ti = text.values()
          let si = start.clone()
          while si.has_next() and ti.has_next() do
            if si.next() != ti.next() then return None end
          end
          if ti.has_next() then return None end
          RuleResult(src, start.clone(), si.clone(), this, )
