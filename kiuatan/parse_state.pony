"""
# Kiuatan

Kiuatan ("horse" or "pony" in [Chinook Jargon](https://en.wikipedia.org/wiki/Chinook_Jargon#Chinook_Jargon_words_used_by_English-language_speakers)) is a library for building and running parsers in the [Pony](https://www.ponylang.org) programming language.

- Kiuatan uses [Parsing Expression Grammar](https://en.wikipedia.org/wiki/Parsing_expression_grammar) semantics, which means:
  - Choices are ordered, i.e. the parser will always try to parse alternatives in the order they are declared.
  - Sequences are greedy, i.e. the parser will not backtrack from the end of a sequence.
  - Parsers do not backtrack from successful choices.
- Kiuatan parsers are "packrat" parsers; they memoize intermediate results, resulting in linear-time parsing.
- Parsers use Mederios et al's [algorithm](https://arxiv.org/abs/1207.0443) to handle unlimited left-recursion.

## Obtaining Kiuatan

### Pony-Stable

The easiest way to incorporate Kiuatan into your Pony project is to use [Pony-Stable](https://github.com/ponylang/pony-stable).  Once you have it installed, `cd` to your project's directory and type:

```bash
stable add github kulibali/kiuatan --tag=0.1.0
```

This will clone the `kiuatan` repository and add it under the `.deps` directory in your project.  To build your project, Pony-Stable will take care of setting the correct `PONYPATH` environment variable for you, e.g.:

```bash
stable env ponyc .
```

### Git

You can clone and build Kiuatan directly from GitHub:

```bash
git clone https://github.com/kulibali/kiuatan.git
cd kiuatan
make && make test
```

To use Kiuatan in a project you will need to add `kiuatan/kiuatan` to your `PONYPATH` environment variable.

## Overview

Kiuatan grammars are designed to match over sequences of items of any type `TSrc` that is `(Equatable[TSrc #read] #read & Stringable #read)`, not just characters.

> In fact, Kiuatan grammars match over linked lists of sequences of items.  For example, you can match over a linked list of strings as if it were a single input string.  You can throw out the parse results for a single node of the linked list and start over, retaining the results for the other nodes.  This might be useful for dynamically parsing source code in an editor.

### Workflow

In order to use Kiuatan to parse some inputs, do the following:

- Build a top-level grammar rule out of the various combinators that implement the [ParseRule](http://kulibali.github.io/kiuatan/kiuatan-ParseRule/) trait (see below).
- Construct a [ParseState](http://kulibali.github.io/kiuatan/kiuatan-ParseState/) object that references a list of sequences of inputs.
- Call `ParseState.parse()` with the top-level grammar rule.

> Note that you can call `parse()` multiple times on the same parse state; subsequent calls will use the results memoized during previous calls.  You can also clear the memo for a particular input segment and parse again (e.g. if that segment has changed by being edited).

### Results

If the parse is successful, you will obtain a [ParseResult](http://kulibali.github.io/kiuatan/kiuatan-ParseResult/) object.  This contains information about the starting and ending positions of the top-level parse rule, as well as results from parsing child rules.

### Custom Result Values

When constructing grammar rules, you can provide lambda functions that act in the context of a parse result and construct a custom value for you.

When you call `ParseResult.value()` on a parse result, it traverses the tree of child results in depth-first post-order, calling the provided lambda functions.  The [ParseActionContext](http://kulibali.github.io/kiuatan/kiuatan-ParseActionContext) contains an array of the child results' values.

> For convenience, the result value of a rule without a lambda function is the last non-`None` value of its child result values.  This allows custom result values to "bubble up" without having to explicitly copy them to parent contexts.

### Error Handling

Kiuatan has a few features for error handling.  You can use the special [RuleError](http://kulibali.github.io/kiuatan/kiuatan-RuleError) combinator to record error messages in the grammar.  The [ParseState](http://kulibali.github.io/kiuatan/kiuatan-ParseState/) class has a few functions for obtaining information about errors:

- `last_error()`: returns information about the last error encountered during parsing.
- `farthest_error()`: returns information about the error encountered at the farthest position from the start.
- `errors(loc)`: returns information about all the rules that failed at a particular location, as well as any error messages that were recorded.

## Details

### [ParseRule](http://kulibali.github.io/kiuatan/kiuatan-ParseRule/)

A parse rule represents a grammar that you want to use for parsing. Kiuatan provides several combinator classes that you can use to construct grammar rules.

- [RuleLiteral](http://kulibali.github.io/kiuatan/kiuatan-RuleLiteral/): matches a literal sequence of source items, e.g. a literal string, if you are matching over characters.
- [RuleClass](http://kulibali.github.io/kiuatan/kiuatan-RuleClass/): matches any one of a set of source items, e.g. a set of possible characters.
- [RuleAny](http://kulibali.github.io/kiuatan/kiuatan-RuleAny/): matches any single input, regardless of what it is.
- [RuleSequence](http://kulibali.github.io/kiuatan/kiuatan-RuleSequence/): matches a sequence of child rules.  If any one of the child rules fails to match, the whole sequence fails.
- [RuleChoice](http://kulibali.github.io/kiuatan/kiuatan-RuleChoice/): tries to match one or more child rules in order, and succeeds on the first match.  A choice rule will not backtrack to a further choice if one has already succeeded.
- [RuleRepeat](http://kulibali.github.io/kiuatan/kiuatan-RuleRepeat/): matches a child rule repeatedly.  You can optionally specify a mininum and/or maximum number of times to match.
- [RuleAnd](http://kulibali.github.io/kiuatan/kiuatan-RuleAnd/): Matches a child rule; if the child succeeds, the rule itself succeeds, but the parse location does not advance.  Used for lookahead.
- [RuleNot](http://kulibali.github.io/kiuatan/kiuatan-RuleNot/): Matches a child rule; if the child **fails**, the rule itself succeeds, but the parse location does not advance.  Used for negative lookahead.
- [RuleError](http://kulibali.github.io/kiuatan/kiuatan-RuleError): Fails the match and records an error message for the match position.

### [ParseLoc](http://kulibali.github.io/kiuatan/kiuatan-ParseLoc/)

A parse location holds a position in a linked list of sequences.  It is analogous to an index into an array.

### [ParseResult](http://kulibali.github.io/kiuatan/kiuatan-ParseResult/)

A parse result stores the results of a successful parse.  Parse results have a number of useful fields:

- `start`: the parse location in the input where the parse began.
- `next`: the parse location just past the end of where the parse ended.
- `results`: results obtained from child rules.
- `inputs()`: copies the inputs that were matched into an array for easy perusal.

### [ParseActionContext](http://kulibali.github.io/kiuatan/kiuatan-ParseActionContext)

A parse action context contains information useful when building custom values from a parse result tree:

- `parent`: the parent action context.  Note that the parent's `children` will not have been populated when the lambda function is called.
- `result`: the parse result for which this value is being generated.
- `children`: the custom result values of the current rule's children.

### [ParseState](http://kulibali.github.io/kiuatan/kiuatan-ParseState/)

A parse state holds the memo for parsing a particular sequence of input.  A few methods of note:

- `parse(rule, loc)`: attempts to parse the input at the given location (the start of the input by default) using the given grammar rule.
- `last_error()`: returns information about the last error encountered during parsing.
- `farthest_error()`: returns information about the error encountered at the farthest position from the start.
- `errors(loc)`: returns information about all the rules that failed at a particular location, as well as any error messages that were recorded.
- `forget_segment(segment)`: clears the memo of any results that were memoized in a given segment of input.
"""

use "collections"

class ParseState[TSrc: Any #read, TVal = None]
  """
  Stores the state of a particular attempt to parse some input.
  """

  let _source: List[ReadSeq[TSrc] box] box

  let _memo_tables: _RuleToExpMemo[TSrc,TVal] = _memo_tables.create()
  let _call_stack: List[_LRRecord[TSrc,TVal]] = _call_stack.create()
  let _cur_recursions: _RuleToLocLR[TSrc,TVal] = _cur_recursions.create()

  var _last_error: (ParseError[TSrc,TVal] | None) = None
  var _farthest_error: (ParseError[TSrc,TVal] | None) = None

  new create(source': List[ReadSeq[TSrc] box] box) =>
    """
    Creates a new parse state using `source'` as the linked list of input
    sequences.
    """
    _source = source'

  new from_single_seq(seq: ReadSeq[TSrc] box) =>
    """
    Creates a new parse state from a single sequence of inputs.
    """
    _source = List[ReadSeq[TSrc]].from([as ReadSeq[TSrc]: seq])

  fun source(): List[ReadSeq[TSrc] box] box =>
    """
    Returns the input source used by this parse state.
    """
    _source

  fun start(): ParseLoc[TSrc] ? =>
    ParseLoc[TSrc](_source.head()?, 0)

  fun last_error(): (this->ParseError[TSrc,TVal] | None) =>
    _last_error

  fun farthest_error(): (this->ParseError[TSrc,TVal] | None) =>
    _farthest_error

  fun errors(loc: ParseLoc[TSrc] box): ParseError[TSrc,TVal] =>
    let rules = SetIs[ParseRule[TSrc,TVal] box]
    let messages = Set[ParseErrorMessage]
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        try
          match loc_memo(loc)?
          | let msg: ParseErrorMessage =>
            messages.set(msg)
          | None =>
            rules.set(rule)
          end
        end
      end
    end
    ParseError[TSrc,TVal](loc, rules, messages)

  fun ref parse(
    rule: ParseRule[TSrc,TVal] box,
    loc: (ParseLoc[TSrc] box | None) = None)
    : (ParseResult[TSrc,TVal] | None)
  =>
    """
    Attempts to parse the input against a particular grammar rule, starting
    at a particular location.  If `loc` is `None`, then the parse will begin
    at the beginning of the source.
    """
    try
      let start' =
        match loc
        | let start'': ParseLoc[TSrc] box =>
          start''
        else
          ParseLoc[TSrc](_source.head()?, 0)
        end

      match parse_with_memo(rule, start')?
      | let res: ParseResult[TSrc,TVal] =>
        res
      end
    end

  fun ref parse_with_memo(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let base_expansion = _Expansion[TSrc,TVal](rule, 0)

    match _get_memoized_result(base_expansion, loc)
    | let r: ParseResult[TSrc,TVal] =>
      r
    else
      if rule.can_be_recursive() then
        _parse_recursive(rule, base_expansion, loc)?
      else
        _parse_non_recursive(rule, base_expansion, loc)?
      end
    end

  fun ref _parse_non_recursive(
    rule: ParseRule[TSrc,TVal] box,
    expansion: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let res = rule.parse(this, loc)?
    _memoize(expansion, loc, res)?
    match res
    | let msg: ParseErrorMessage =>
      _record_error(rule, msg, loc)
    end
    res

  fun ref _parse_recursive(
    rule: ParseRule[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    match _get_lr_record(rule, loc)
    | let rec: _LRRecord[TSrc,TVal] =>
      _parse_existing_lr(rule, rec, loc)
    else
      _parse_new_lr(rule, exp, loc)?
    end

  fun ref _parse_existing_lr(
    rule: ParseRule[TSrc,TVal] box,
    rec: _LRRecord[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None)
  =>
    rec.lr_detected = true
    for lr in _call_stack.values() do
      if lr.cur_expansion.rule is rule then break end
      rec.involved_rules.set(lr.cur_expansion.rule)
    end
    _get_memoized_result(rec.cur_expansion, loc)

  fun ref _parse_new_lr(
    rule: ParseRule[TSrc,TVal] box,
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box)
    : (ParseResult[TSrc,TVal] | ParseErrorMessage | None) ?
  =>
    let rec = _LRRecord[TSrc,TVal](rule, loc)
    _memoize(rec.cur_expansion, loc, None)?
    _start_lr_record(rule, loc, rec)
    _call_stack.unshift(rec)

    var res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None) = None
    while true do
      res = rule.parse(this, loc)?
      match res
      | (let r: ParseResult[TSrc,TVal])
        if rec.lr_detected and (r.next > rec.cur_next_loc) =>
        rec.num_expansions = rec.num_expansions + 1
        rec.cur_expansion = _Expansion[TSrc,TVal](rule, rec.num_expansions)
        rec.cur_next_loc = r.next
        rec.cur_result = r
        _memoize(rec.cur_expansion, loc, r)?
      else
        if rec.lr_detected then
          res = rec.cur_result
        end
        _forget_lr_record(rule, loc)
        _call_stack.shift()?
        if not _call_stack.exists(
          {(r: _LRRecord[TSrc,TVal] box): Bool =>
            r.involved_rules.contains(rule) }) then
          _memoize(exp, loc, res)?
        end

        match res
        | let msg: ParseErrorMessage =>
          _record_error(rule, msg, loc)
        end
        break
      end
    end
    res

  fun ref _record_error(
    rule: ParseRule[TSrc,TVal] box,
    msg: ParseErrorMessage,
    loc: ParseLoc[TSrc] box)
  =>
    match _last_error
    | let err: ParseError[TSrc,TVal] =>
      err.loc = loc
      err.rules.clear()
      err.rules.set(rule)
      err.messages.clear()
      err.messages.set(msg)
    else
      _last_error =
        ParseError[TSrc,TVal](
          loc,
          SetIs[ParseRule[TSrc,TVal] box].>set(rule),
          Set[ParseErrorMessage].>set(msg))
    end

    match _farthest_error
    | let err: ParseError[TSrc,TVal] =>
      if loc >= err.loc then
        if not (loc == err.loc) then
          err.loc = loc
          err.rules.clear()
          err.messages.clear()
        end
        err.rules.set(rule)
        err.messages.set(msg)
      end
    else
      _farthest_error =
        ParseError[TSrc,TVal](
          loc,
          SetIs[ParseRule[TSrc,TVal] box].>set(rule),
          Set[ParseErrorMessage].>set(msg))
    end

  fun _get_memoized_result(
    exp: _Expansion[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (this->ParseResult[TSrc,TVal] | ParseErrorMessage | None)
  =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo(loc)?
    else
      None
    end

  fun ref _memoize(
    exp: _Expansion[TSrc,TVal],
    loc: ParseLoc[TSrc] box,
    res: (ParseResult[TSrc,TVal] | ParseErrorMessage | None)) ?
  =>
    let exp_memo = try
      _memo_tables(exp.rule)?
    else
      _memo_tables.insert(exp.rule, _ExpToLocMemo[TSrc,TVal]())?
    end

    let loc_memo = try
      exp_memo(exp.num)?
    else
      exp_memo.insert(exp.num, _LocToResultMemo[TSrc,TVal]())?
    end

    loc_memo.insert(loc, res)?

  fun ref _forget(exp: _Expansion[TSrc,TVal], loc: ParseLoc[TSrc]) =>
    try
      let exp_memo = _memo_tables(exp.rule)?
      let loc_memo = exp_memo(exp.num)?
      loc_memo.remove(loc)?
    end

  fun ref forget_segment(segment: ParseSegment[TSrc]) =>
    for (rule, exp_memo) in _memo_tables.pairs() do
      for (exp, loc_memo) in exp_memo.pairs() do
        let to_delete = Array[ParseLoc[TSrc] box]
        for (loc, _) in loc_memo.pairs() do
          if loc.segment() is segment then
            to_delete.push(loc)
          end
        end
        for loc in to_delete.values() do
          try loc_memo.remove(loc)? end
        end
      end
    end

  fun ref _get_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
    : (_LRRecord[TSrc,TVal] | None)
  =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr(loc)?
    else
      None
    end

  fun ref _start_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box,
    rec: _LRRecord[TSrc,TVal])
  =>
    try
      let loc_lr = try
        _cur_recursions(rule)?
      else
        _cur_recursions.insert(rule, _LocToLR[TSrc,TVal]())?
      end

      loc_lr.insert(loc, rec)?
    end

  fun ref _forget_lr_record(
    rule: ParseRule[TSrc,TVal] box,
    loc: ParseLoc[TSrc] box)
  =>
    try
      let loc_lr = _cur_recursions(rule)?
      loc_lr.remove(loc)?
    end


class ParseError[TSrc: Any #read, TVal = None]
  var loc: ParseLoc[TSrc] box
  let rules: SetIs[ParseRule[TSrc,TVal] box]
  let messages: Set[ParseErrorMessage]

  new create(
    loc': ParseLoc[TSrc] box,
    rules': SetIs[ParseRule[TSrc,TVal] box],
    msg': Set[ParseErrorMessage])
  =>
    loc = loc'
    rules = rules'
    messages = msg'


type ParseErrorMessage is String

type _RuleToExpMemo[TSrc: Any #read, TVal] is
  MapIs[ParseRule[TSrc,TVal] box, _ExpToLocMemo[TSrc,TVal]]

type _ExpToLocMemo[TSrc: Any #read, TVal] is
  Map[USize, _LocToResultMemo[TSrc,TVal]]

type _LocToResultMemo[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, (ParseResult[TSrc,TVal] | ParseErrorMessage | None)]

type _RuleToLocLR[TSrc: Any #read, TVal] is
  MapIs[ParseRule[TSrc,TVal] box, _LocToLR[TSrc,TVal]]

type _LocToLR[TSrc: Any #read, TVal] is
  Map[ParseLoc[TSrc] box, _LRRecord[TSrc,TVal]]


class _Expansion[TSrc: Any #read, TVal]
  let rule: ParseRule[TSrc,TVal] box
  let num: USize

  new create(rule': ParseRule[TSrc,TVal] box, num': USize) =>
    rule = rule'
    num = num'


class _LRRecord[TSrc: Any #read, TVal]
  var lr_detected: Bool
  var num_expansions: USize
  var cur_expansion: _Expansion[TSrc,TVal]
  var cur_next_loc: ParseLoc[TSrc] box
  var cur_result: (ParseResult[TSrc,TVal] | None)
  var involved_rules: SetIs[ParseRule[TSrc,TVal] box]

  new create(rule: ParseRule[TSrc,TVal] box, loc: ParseLoc[TSrc] box) =>
    lr_detected = false
    num_expansions = 1
    cur_expansion = _Expansion[TSrc,TVal](rule, num_expansions)
    cur_next_loc = loc
    cur_result = None
    involved_rules = SetIs[ParseRule[TSrc,TVal] box]
