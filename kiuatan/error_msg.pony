primitive ErrorMsg
  fun tag empty_source(): String val =>
    "cannot parse empty source"

  fun tag literal_failed(): String val =>
    "Literal combinator failed unexpectedly"

  fun tag _lr_started(): String val => "LR started"
  fun tag _lr_not_memoized(): String val => "LR not memoized"
