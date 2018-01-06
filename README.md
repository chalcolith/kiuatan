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

- Build a top-level grammar rule of type [ParseRule](http://kulibali.github.io/kiuatan/kiuatan-ParseRule/) out of the various combinators that implement the [RuleNode](http://kulibali.github.io/kiuatan/kiuatan-RuleNode/) trait (see below).
- Construct a [ParseState](http://kulibali.github.io/kiuatan/kiuatan-ParseState/) object that references a list of sequences of inputs.
- Call `ParseState.parse()` with the top-level grammar rule.

> Note that you can call `parse()` multiple times on the same parse state; subsequent calls will use the results memoized during previous calls.  You can also clear the memo for a particular input segment and parse again (e.g. if that segment has changed by being edited).

### Results

If the parse is successful, you will obtain a [ParseResult](http://kulibali.github.io/kiuatan/kiuatan-ParseResult/) object.  This contains information about the starting and ending positions of the top-level parse rule, as well as results from parsing child rules.

### Custom Result Values

When constructing grammar rules, you can provide lambda functions for any node in the rule that act in the context of a parse result and construct a custom value for you.

When you call `ParseResult.value()` on a parse result, it traverses the tree of child results in depth-first post-order, calling the provided lambda functions.  The [ParseActionContext](http://kulibali.github.io/kiuatan/kiuatan-ParseActionContext) contains an array of the child results' values.

> For convenience, the result value of a rule without a lambda function is the last non-`None` value of its child result values.  This allows custom result values to "bubble up" without having to explicitly copy them to parent contexts.

### Error Handling

Kiuatan has a few features for error handling.  You can use the special [RuleError](http://kulibali.github.io/kiuatan/kiuatan-RuleError) combinator to record error messages in the grammar.  The [ParseState](http://kulibali.github.io/kiuatan/kiuatan-ParseState/) class has a few functions for obtaining information about errors:

- `last_error()`: returns information about the last error encountered during parsing.
- `farthest_error()`: returns information about the error encountered at the farthest position from the start.
- `errors(loc)`: returns information about all the rules that failed at a particular location, as well as any error messages that were recorded.

## Details

### [ParseRule](http://kulibali.github.io/kiuatan/kiuatan-ParseRule/)

A parse rule is a named rule (terminal or non-terminal) in the grammar.  Left-recursion detection and handling only applies to parse rules, so it is safe to include them as children of nodes in themselves or other rules.  Do not use other types of nodes recursively!

### [RuleNode](http://kulibali.github.io/kiuatan/kiuatan-RuleNode/)

A parse node represents a grammar that you want to use for parsing. Kiuatan provides several combinator classes that you can use to construct grammar rules.

- [RuleLiteral](http://kulibali.github.io/kiuatan/kiuatan-RuleLiteral/): matches a literal sequence of source items, e.g. a literal string, if you are matching over characters.
- [RuleClass](http://kulibali.github.io/kiuatan/kiuatan-RuleClass/): matches any one of a set of source items, e.g. a set of possible characters.
- [RuleAny](http://kulibali.github.io/kiuatan/kiuatan-RuleAny/): matches any single input, regardless of what it is.
- [RuleSequence](http://kulibali.github.io/kiuatan/kiuatan-RuleSequence/): matches a sequence of child nodes.  If any one of the child nodes fails to match, the whole sequence fails.
- [RuleChoice](http://kulibali.github.io/kiuatan/kiuatan-RuleChoice/): tries to match one or more child nodes in order, and succeeds on the first match.  A choice node will not backtrack to a further choice if one has already succeeded.
- [RuleRepeat](http://kulibali.github.io/kiuatan/kiuatan-RuleRepeat/): matches a child node repeatedly.  You can optionally specify a mininum and/or maximum number of times to match.
- [RuleAnd](http://kulibali.github.io/kiuatan/kiuatan-RuleAnd/): Matches a child node; if the child succeeds, the node itself succeeds, but the parse location does not advance.  Used for lookahead.
- [RuleNot](http://kulibali.github.io/kiuatan/kiuatan-RuleNot/): Matches a child node; if the child **fails**, the node itself succeeds, but the parse location does not advance.  Used for negative lookahead.
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

## Example

The following example is a Pony class that creates a simple mathematical expression parser.

```pony

use "kiuatan"

primitive Calculator
  """
  An example of very simple expression parser for the following grammar:

  ```
  Exp = Add
  Add = Add WS [+-] WS Mul
      | Mul
  Mul = Mul WS [*/] WS Num
      | Num
  Num = '(' WS Exp ')' WS
      | [0-9]+ WS
  WS = [ \t]*
  ```
  """

  fun generate(): ParseRule[U8,ISize] =>
    // We pre-declare the Exp rule so we can use it later for recursion.
    let exp = ParseRule[U8,ISize]("Exp")

    // A simple whitespace rule: 0 or more repeats of space or tab.
    let ws = 
      ParseRule[U8,ISize].terminal(
        "WS",
        RuleRepeat[U8,ISize](
          RuleClass[U8,ISize].from_iter(" \t".values()),
          None,
          0))

    // A number can be either an expression in parentheses, or a string
    // of digits.
    let num =
      ParseRule[U8,ISize](
        "Num",
        RuleChoice[U8,ISize](
          [ RuleSequence[U8,ISize](
              [ RuleLiteral[U8,ISize]("(")
                ws
                exp
                RuleLiteral[U8,ISize](")")
                ws
              ])
            RuleSequence[U8,ISize](
              [ RuleRepeat[U8,ISize](
                  RuleClass[U8,ISize].from_iter("0123456789".values()),
                  // A semantic action that converts the string of digits to a
                  // decimal number.
                  {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
                    var num: ISize = 0
                    for ch in ctx.result.inputs().values() do
                      num = (num * 10) + (ch.isize() - '0')
                    end
                    num
                  },
                  1)
                ws
              ])
          ]))

    // A multiplicative expression can be a multiplicative expression
    // then a * or /, then a number; or a number.
    let mul = ParseRule[U8,ISize]("Mul")
    mul.set_child(
      RuleChoice[U8,ISize](
        [ RuleSequence[U8,ISize](
            [ mul
              ws
              RuleClass[U8,ISize].from_iter("*/".values())
              ws
              num ],
            // A semantic action that multiplies or divides the operands.
            {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
              try
                let a = ctx.children(0)? as ISize
                let b = ctx.children(4)? as ISize

                let str = ctx.result.results(2)?.inputs()
                if str(0)? == '*' then
                  a * b
                else
                  a / b
                end
              end
            })
          num 
        ]))

    // An additive expression can be an additive expression then a + or -,
    // then a multiplicative expression; or a multiplicative expression.
    let add = ParseRule[U8,ISize]("Add")
    add.set_child(
      RuleChoice[U8,ISize](
        [ RuleSequence[U8,ISize](
            [ add
              ws
              RuleClass[U8,ISize].from_iter("+-".values())
              ws
              mul ],
            {(ctx: ParseActionContext[U8,ISize] box) : (ISize | None) =>
              try
                let a = ctx.children(0)? as ISize
                let b = ctx.children(4)? as ISize

                let str = ctx.result.results(2)?.inputs()
                if str(0)? == '+' then
                  a + b
                else
                  a - b
                end
              end
            })
          mul 
        ]))

    exp.set_child(add)
    exp
```

To use this grammar for parsing, you can do something like the following:

```pony

let grammar = Calculator.generate()
let state = ParseState[U8,ISize].from_single_seq("123 + (4 * 12)")
match state.parse(grammar)
| let result: ParseResult[U8,ISize] =>
  match result.value()
  | let actual: ISize =>
    // actual should equal 171
  end
end

```

