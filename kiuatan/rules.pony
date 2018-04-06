
use "collections/persistent"

class val Single[S: (Any #read & Equatable[S]), V = None]
  """
  Matches a single item.  If given a list of possibilities, will only succeed if it matches one of them.  Otherwise, it succeeds for any single item.
  """
  let _expected: ReadSeq[S] val
  let _action: (Action[S, V] | None)

  new create(expected: ReadSeq[S] val = [],
    action: (Action[S, V] | None) = None)
  =>
    _expected = expected
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    try
      if loc.has_value() then
        if _expected.size() > 0 then
          for exp in _expected.values() do
            if exp == loc()? then
              cont(Success[S, V](this, loc, loc.next()), stack, recur)
              return
            end
          end
        else
          cont(Success[S, V](this, loc, loc.next()), stack, recur)
          return
        end
      end
    end
    cont(Failure[S, V](this, loc, "any failed"), stack, recur)

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].emptyAction()
    end


class val Literal[S: (Any #read & Equatable[S]), V = None]
  """
  Matches a string of items.
  """
  let _expected: ReadSeq[S] val
  let _action: (Action[S, V] | None)

  new create(expected: ReadSeq[S] val, action: (Action[S, V] | None) = None) =>
    _expected = expected
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    try
      var act = loc
      for exp in _expected.values() do
        if (not act.has_value()) or (exp != act()?) then
          cont(Failure[S, V](this, loc), stack, recur)
          return
        end
        act = act.next()
      end
      cont(Success[S, V](this, loc, act), stack, recur)
    else
      cont(Failure[S, V](this, loc, "literal failed"), stack, recur)
    end

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].emptyAction()
    end


class val Conj[S, V = None]
  """
  Matches a sequence of child rules.
  """
  let _children: ReadSeq[RuleNode[S, V] box]
  let _action: (Action[S, V] | None)

  new create(children: ReadSeq[RuleNode[S, V] box],
    action: (Action[S, V] | None) = None)
  =>
    _children = children
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      let stack' = stack.prepend(rule)
      for child in _children.values() do
        if not child._is_terminal(stack') then
          return false
        end
      end
      true
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    _parse_one(0, loc, parser, src, loc, stack, recur, cont,
      Lists[Success[S, V]].empty())

  fun val _parse_one(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V],
    results: List[Success[S, V]])
  =>
    if child_index == _children.size() then
      cont(Success[S, V](this, start, loc, results.reverse()), stack, recur)
    else
      try
        let rule = this
        let cont' =
          recover
            {(result: Result[S, V], stack': List[_LRRecord[S, V]],
              recur': _LRByRule[S, V])
            =>
              match result
              | let success: Success[S, V] =>
                rule._parse_one(child_index + 1, start, parser, src,
                  success.next, stack', recur', cont,
                  results.prepend(success))
              | let failure: Failure[S, V] =>
                cont(Failure[S, V](rule, start, "", failure), stack',
                  recur')
              end
            }
          end

        parser._parse_with_memo(_children(child_index)?, src, loc, stack,
          recur, consume cont')
      else
        cont(Failure[S, V](this, start, "conj failed"), stack, recur)
      end
    end

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].defaultAction()
    end


class val Disj[S, V = None]
  """
  Matches one out of a list of possible alternatives.  Tries each alternative in order.  If one alternative fails, but an outer rule later fails, will *not* backtrack to another alternative.
  """
  let _children: ReadSeq[RuleNode[S, V] box]
  let _action: (Action[S, V] | None)

  new create(children: ReadSeq[RuleNode[S, V] box],
    action: (Action[S, V] | None) = None)
  =>
    _children = children
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      let stack' = stack.prepend(rule)
      for child in _children.values() do
        if not child._is_terminal(stack') then
          return false
        end
      end
      true
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    _parse_one(0, loc, parser, src, loc, stack, recur, cont)

  fun val _parse_one(
    child_index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    if child_index == _children.size() then
      cont(Failure[S, V](this, start), stack, recur)
    else
      try
        let rule = this
        let cont' =
          recover
            {(result: Result[S, V], stack': List[_LRRecord[S, V]],
              recur': _LRByRule[S, V])
            =>
              match result
              | let success: Success[S, V] =>
                cont(Success[S, V](rule, start, success.next, [success]),
                  stack', recur')
              | let failure: Failure[S, V] =>
                rule._parse_one(child_index + 1, start, parser, src,
                  start, stack', recur', cont)
              end
            }
          end

        parser._parse_with_memo(_children(child_index)?, src, start, stack,
          recur, consume cont')
      else
        cont(Failure[S, V](this, start, "disj failed"), stack, recur)
      end
    end

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].defaultAction()
    end


class val Error[S, V = None]
  """
  Will result in an error with the given message.
  """
  let _message: String
  let _action: (Action[S, V] | None)

  new create(message: String, action: (Action[S, V] | None) = None) =>
    _message = message
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    true

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    cont(Failure[S, V](this, loc, _message), stack, recur)

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].emptyAction()
    end


class val Look[S, V = None]
  """
  Positive lookahead: will succeed if its child rule matches, but will not advance the match position.
  """
  let _body: RuleNode[S, V] box
  let _action: (Action[S, V] | None)

  new create(body: RuleNode[S, V] box, action: (Action[S, V] | None) = None) =>
    _body = body
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body._is_terminal(stack.prepend(rule))
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let rule = this
    let cont' =
      recover
        {(result: Result[S, V], stack': List[_LRRecord[S, V]],
          recur': _LRByRule[S, V])
        =>
          match result
          | let success: Success[S, V] =>
            cont(Success[S, V](rule, loc, loc), stack', recur')
          | let failure: Failure[S, V] =>
            cont(Failure[S, V](rule, loc, "lookahead failed", failure),
              stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].emptyAction()
    end


class val Neg[S, V = None]
  """
  Negative lookahead: will succeed if its child rule does not match, and will not advance the match position.
  """
  let _body: RuleNode[S, V] box
  let _action: (Action[S, V] | None)

  new create(body: RuleNode[S, V] box, action: (Action[S, V] | None) = None) =>
    _body = body
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body._is_terminal(stack.prepend(rule))
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let rule = this
    let cont' =
      recover
        {(result: Result[S, V], stack': List[_LRRecord[S, V]],
          recur': _LRByRule[S, V])
        =>
          match result
          | let success: Success[S, V] =>
            cont(Failure[S, V](rule, loc, "neg failed"), stack', recur')
          | let failure: Failure[S, V] =>
            cont(Success[S, V](rule, loc, loc), stack', recur')
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].emptyAction()
    end


class val Star[S, V = None]
  """
  A generalization of Kleene star: will match from `min` to `max` repetitions of its child rule.
  """
  let _body: RuleNode[S, V] box
  let _min: USize
  let _max: USize
  let _action: (Action[S, V] | None)

  new create(body: RuleNode[S, V] box, min: USize = 0,
    action: (Action[S, V] | None) = None, max: USize = USize.max_value())
  =>
    _body = body
    _min = min
    _max = max
    _action = action

  fun val _is_terminal(stack: List[RuleNode[S, V] tag]): Bool =>
    let rule = this
    if stack.exists({(x) => x is rule}) then
      false
    else
      _body._is_terminal(stack.prepend(rule))
    end

  fun val _parse(
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    _parse_one(0, loc, parser, src, loc, stack, recur, cont)

  fun val _parse_one(
    index: USize,
    start: Loc[S],
    parser: Parser[S, V],
    src: Source[S],
    loc: Loc[S],
    stack: List[_LRRecord[S, V]],
    recur: _LRByRule[S, V],
    cont: _Cont[S, V])
  =>
    let rule = this
    let cont' =
      recover
        {(result: Result[S, V], stack': List[_LRRecord[S, V]],
          recur': _LRByRule[S, V])
        =>
          match result
          | let success: Success[S, V] =>
            if index == _max then
              cont(Failure[S, V](rule, start, "star succeeded too often"),
                stack', recur')
            else
              rule._parse_one(index + 1, start, parser, src,
                success.next, stack', recur', cont)
            end
          | let failure: Failure[S, V] =>
            if index >= _min then
              cont(Success[S, V](rule, start, loc), stack', recur')
            else
              cont(Failure[S, V](rule, start,
                "star did not match enough times"), stack', recur')
            end
          end
        }
      end
    parser._parse_with_memo(_body, src, loc, stack, recur, consume cont')

  fun val _get_action(): Action[S, V] =>
    match _action
    | let action: Action[S, V] =>
      action
    else
      Rules[S, V].defaultAction()
    end


primitive Rules[S, V = None]
  fun defaultAction(): Action[S, V] =>
    {(ctx) =>
      try
        var i = ctx.child_values.size()
        while i > 0 do
          match ctx.child_values(i-1)?
          | let v: V =>
            return consume v
          end
          i = i - 1
        end
      end
      None
    }

  fun emptyAction(): Action[S, V] =>
    {(_) => None}
