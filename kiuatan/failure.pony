class val Failure[S, D: Any #share = None, V: Any #share = None]
  """
  The result of a failed match.
  """

  let node: RuleNode[S, D, V] val
  let start: Loc[S]
  let message: (String | None)
  let inner: (Failure[S, D, V] | None)

  new val create(
    node': RuleNode[S, D, V] val,
    start': Loc[S],
    message': (String | None) = None,
    inner': (Failure[S, D, V] | None) = None)
  =>
    node = node'
    start = start'
    message = message'
    inner = inner'

  fun get_message(): String =>
    recover
      let s = String
      let message' = match message | let m: String => m else "" end
      if message'.size() > 0 then
        s.append("[")
        s.append(message')
      end
      match inner
      | let inner': Failure[S, D, V] =>
        let inner_msg = inner'.get_message()
        if inner_msg.size() > 0 then
          if message'.size() > 0 then
            s.append(": ")
          end
          s.append(inner_msg)
        end
      end
      if (message'.size() > 0) then
        s.append("]")
      end
      s
    end

  fun string(): String iso^ =>
    recover
      let s = String
      match node
      | let rule: NamedRule[S, D, V] val =>
        s.append("Failure(" + rule.name + "@" + start.string() + ")")
      else
        s.append("Failure(@" + start.string() + ")")
      end
      s
    end
