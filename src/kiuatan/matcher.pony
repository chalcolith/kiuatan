
class MatchState[TSrc,TRes]
  """
  Stores the memo and matcher stack for a particular match.
  """

  let source: MatchSource[TSrc]
  let start: MatchLoc[TSrc]

  new create(source': MatchSource[TSrc], start': (MatchLoc[TSrc] | None) = None) =>
    source = source'
    start = match start'
      | None => source.begin()
      | let s: MatchLoc[TSrc] => s.clone()
    end


class MatchResult[TSrc,TRes]
  let start: MatchLoc[TSrc]
  let next: MatchLoc[TSrc]
  let res: (TRes | None)

  new create(start': MatchLoc[TSrc], next': MatchLoc[TSrc], res': (TRes | None)) =>
    start = start'.clone()
    next = next'.clone()
    res = res'


type MatchArg is (None)
