class box Failure[
  S: (Any #read & Equatable[S]),
  D: Any #share = None,
  V: Any #share = None]
  """
  The result of a failed match.
  """

  let node: RuleNode[S, D, V] box
  let start: Loc[S]
  let message: (String | None)
  let inner: (Failure[S, D, V] | None)
  let from_error: Bool

  new create(
    node': RuleNode[S, D, V] box,
    start': Loc[S],
    message': (String | None) = None,
    inner': (Failure[S, D, V] | None) = None,
    from_error': Bool = false)
  =>
    node = node'
    start = start'
    message = message'
    inner = inner'
    from_error = from_error'

  fun get_message(): String =>
    let msg: String trn = String
    match message
    | let message': String =>
      msg.append(message')
    end
    match inner
    | let inner': Failure[S, D, V] =>
      let inner_msg = inner'.get_message()
      if inner_msg.size() > 0 then
        if msg.size() > 0 then
          msg.append(" [" + inner_msg + "]")
        else
          msg.append(inner_msg)
        end
      end
    end
    consume msg

  fun string(): String iso^ =>
    let msg =
      match message
      | let message': String =>
        message'
      else
        "syntax error"
      end
    match node
    | let rule: NamedRule[S, D, V] box =>
      "Failure(" + rule.name + "@" + start.string() + ": " + msg + ")"
    else
      "Failure(@" + start.string() + ": " + msg + ")"
    end
