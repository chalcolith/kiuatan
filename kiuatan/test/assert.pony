
use "collections/persistent"
use "itertools"
use "ponytest"
use "promises"
use ".."

type _Segment[T] is ReadSeq[T] val


primitive Assert[S: Stringable #read,
  V: (Equatable[V] val & Stringable val) = None]

  fun test_promises(h: TestHelper, promises: ReadSeq[Promise[Bool]]) =>
    Promises[Bool].join(promises.values())
      .next[None]({(r) =>
        let succeeded = Iter[Bool](r.values()).all({(x) => x})
        h.complete(succeeded)
      })
    h.long_test(10_000_000_000)

  fun test_matches(
    h: TestHelper,
    grammar: Rule[S, V],
    should_match: Bool,
    source: ReadSeq[Segment[S]] val,
    start_index: USize,
    length: USize,
    expected_value: (V | None) = None,
    expected_msg: (String | None) = None) : Promise[Bool]
  =>
    let promise = Promise[Bool]
    let parser = Parser[S, V](source)

    let src_list = Lists[Segment[S]].from(source.values())
    let first_loc = Loc[S](src_list)
    let start_exp = first_loc + start_index
    let next_exp = start_exp + length

    parser.parse(grammar, {(result) =>
      h.log("test_matches " + start_index.string() + " " + length.string()
        + " " + should_match.string())
      match result
      | let success: Success[S, V] =>
        if should_match then
          h.assert_eq[Loc[S]](start_exp, success.start)
          h.assert_eq[Loc[S]](next_exp, success.next)
          match expected_value
          | None =>
            None
          | let expected: V =>
            match success.value()
            | let actual: V =>
              h.assert_eq[V](expected, actual)
            else
              h.fail("expected " + expected.string() + "; no value returned")
            end
          end
          promise(true)
        else
          h.fail("match succeeded; should have failed")
          promise(false)
        end
      | let failure: Failure[S, V] =>
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
              h.assert_true(act_msg.contains(exp_msg), "'" + act_msg +
                "' does not contain '" + exp_msg + "'")
            end
          end
          promise(true)
        end
      end
    }, start_exp)
    promise
