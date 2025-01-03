
use "collections/persistent"
use "itertools"
use "pony_test"
use "promises"

use ".."

type _Segment[T] is ReadSeq[T] val

primitive \nodoc\ Assert[S: (Stringable #read & Equatable[S] #read),
  D: Any #share = None, V: (Equatable[V] val & Stringable val) = None]

  fun test_promises(h: TestHelper, promises: ReadSeq[Promise[Bool]]) =>
    Promises[Bool].join(promises.values())
      .next[None]({(r) =>
        let succeeded = Iter[Bool](r.values()).all({(x) => x})
        h.complete(succeeded)
      })
    h.long_test(10_000_000_000)

  fun test_matches(
    h: TestHelper,
    rule: NamedRule[S, D, V] val,
    should_match: Bool,
    source: ReadSeq[Segment[S]] val,
    start_index: USize,
    length: USize,
    data: (D | None) = None,
    expected_value: (V | None) = None,
    expected_msg: (String | None) = None) : Promise[Bool]
  =>
    let promise = Promise[Bool]
    let parser = Parser[S, D, V](source)

    let src_list = Lists[Segment[S]].from(source.values())
    let first_loc = Loc[S](src_list)
    let start_exp = first_loc + start_index
    let next_exp = start_exp + length

    try
      parser.parse(rule, data as D,
        this~_handle_result(h, promise, should_match, start_index, length,
          start_exp, next_exp, expected_value, expected_msg),
        start_exp)
      promise
    else
      promise.>apply(false)
    end

  fun _handle_result(h: TestHelper, promise: Promise[Bool],
    should_match: Bool, start_index: USize, length: USize,
    start_exp: Loc[S], next_exp: Loc[S], expected_value: (V | None),
    expected_msg: (String | None), result: Result[S, D, V],
    result_values: ReadSeq[V])
  =>
    h.log("test_matches " + start_index.string() + " " + length.string()
      + " " + should_match.string())
    match result
    | let success: Success[S, D, V] =>
      if should_match then
        h.assert_eq[Loc[S]](start_exp, success.start)
        h.assert_eq[Loc[S]](next_exp, success.next)
        match expected_value
        | None =>
          None
        | let expected: V =>
          try
            h.assert_eq[V](expected, result_values(result_values.size() - 1)?)
          else
            h.fail("expected " + expected.string() + "; no value returned")
          end
        end
        promise(true)
      else
        h.fail("match succeeded; should have failed")
        promise(false)
      end
    | let failure: Failure[S, D, V] =>
      if should_match then
        h.fail("match failed; should have succeeded")
        promise(false)
      else
        match expected_msg
        | let exp_msg: String =>
          if exp_msg != "" then
            let act_msg = failure.get_message()
            h.log(exp_msg)
            h.log(act_msg)
            h.assert_true(
              act_msg.contains(exp_msg), "'" + act_msg +
              "' does not contain '" + exp_msg + "'")
          end
        end
        promise(true)
      end
    end

  fun iter_eq(a: Iterator[S], b: Iterator[S]): Bool =>
    var a_has_next = a.has_next()
    var b_has_next = b.has_next()

    while a_has_next and b_has_next do
      try
        if a.next()? != b.next()? then
          return false
        end
      else
        return false
      end
      a_has_next = a.has_next()
      b_has_next = b.has_next()
    end
    (not a_has_next) and (not b_has_next)
