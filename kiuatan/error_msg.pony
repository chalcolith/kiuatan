primitive ErrorMsg
  fun tag empty_source(): String val =>
    "cannot parse empty source"

  fun tag literal_unexpected(): String val =>
    "unexpected value"

  fun tag literal_failed(): String val =>
    "literal combinator failed unexpectedly"

  fun tag condition_failed(): String val =>
    "conditional combinator's condition failed"

  fun tag conjunction_failed(): String val =>
    "conjunction (sequence) combinator failed unexpectedly"

  fun tag disjunction_empty(): String val =>
    "disjunction contained no alternatives"

  fun tag disjunction_failed(): String val =>
    "disjunction combinator failed unexpectedly"

  fun tag disjunction_none(): String val =>
    "all alternatives failed"

  fun tag single_failed(): String val =>
    "single-item combinator failed unexpectedly"

  fun tag star_too_long(): String val =>
    "star combinator succeeded too many times"

  fun tag star_too_short(): String val =>
    "star combinator did not match enough times"

  fun tag rule_expected(name: String, loc: String): String val =>
    "expected " + name

  fun tag rule_empty(name: String): String val =>
    "named rule combinator '" + name + "' has no body"

  fun tag _lr_started(): String val => "LR started"

  fun tag _lr_not_memoized(): String val => "LR not memoized"

  fun tag internal_error(): String val => "internal error"
