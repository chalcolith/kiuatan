
trait GrammarRule[TSrc,TRes]
  """
  A rule in a grammar.
  """

  fun parse(memo: MatchState[TSrc,TRes],
    start: MatchLoc[TSrc],
    args: (Seq[MatchArg] | None) = None,
    argStart: USize = 0): (MatchResult[TSrc,TRes] | None)


// class GrammarSeq[TSrc,TRes] is GrammarRule[TSrc,TRes]
//   var _left: GrammarRule[TSrc,TRes]
//   var _right: GrammarRule[TSrc,TRes]
//
//   new create(left: GrammarRule[TSrc,TRes], right: GrammarRule[TSrc,TRes]) =>
//     _left = left
//     _right = right


class GrammarLiteral[TSrc,TRes] is GrammarRule[TSrc,TRes]
  var _str: Seq[TSrc]
  var _bld: ({(MatchSource[TSrc], MatchLoc[TSrc], MatchLoc[TSrc]): TRes} | None)

  new create(str: Seq[TSrc], bld: ({(MatchSource[TSrc], MatchLoc[TSrc], MatchLoc[TSrc]): TRes} val | None) = None) =>
    _str = str
    _bld = bld

  fun parse(memo: MatchState[TSrc,TRes],
    start: MatchLoc[TSrc],
    args: (Seq[MatchArg] | None) = None,
    argStart: USize = 0) : (MatchResult[TSrc,TRes] | None) =>

    let cur = start.clone()
    for expected in _str do
      if not cur.has_next() then return None end

      let actual = cur.next()
      if expected != actual then return None end
    end

    match _bld
    | None => None
    | let bld: ({(MatchSource[TSrc], MatchLoc[TSrc], MatchLoc[TSrc]): TRes}) =>
      MatchResult[TSrc,TRes](start, cur, bld(memo.source, start, cur))
    end
