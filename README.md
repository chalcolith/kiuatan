# Kiuatan

Kiuatan ("horse" or "pony" in [Chinook Jargon](https://en.wikipedia.org/wiki/Chinook_Jargon#Chinook_Jargon_words_used_by_English-language_speakers)) is a library for building and running parsers in the [Pony](https://www.ponylang.org) programming language.

- Kiuatan parsers use [Parsing Expression Grammar](https://en.wikipedia.org/wiki/Parsing_expression_grammar) semantics, which means choices are ordered, and parsers do not backtrack from successful choices.
- Parsers are "packrat" parsers; they memoize intermediate results, resulting in linear-time parsing.
- Parsers use Mederios et al's [algorithm](https://arxiv.org/abs/1207.0443) to handle unlimited left-recursion.

## Obtaining Kiuatan

### Pony-Stable

The easiest way to incorporate Kiuatan into your Pony project is to use [Pony-Stable](https://github.com/ponylang/pony-stable).  Once you have it installed, `cd` to your project's directory and type:

```bash
stable add github kulibali/kiuatan
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

To use Kiuatan in a project you will need to add `kiuatan/bin` to your `PONYPATH` environment variable.

## Overview

Kiuatan is very flexible. Kiuatan grammars are designed to match over linked lists of sequences of items of any type `TSrc` that is `(Equatable[TSrc #read] #read & Stringable #read)`.  (The idea behind this is that you can match not just a single string, but a series of strings stored in a linked list.)

There are a few fundamental concepts:

### [ParseRule](http://kulibali.github.io/kiuatan/kiuatan-ParseRule/)

A parse rule represents a grammar that you want to use for parsing. Kiuatan provides several classes that you can use to construct grammars.

- [RuleLiteral](http://kulibali.github.io/kiuatan/kiuatan-RuleLiteral/): matches a literal sequence of source items, e.g. a literal string, if you are matching over characters.
- [RuleClass](http://kulibali.github.io/kiuatan/kiuatan-RuleClass/): matches any one of a set of source items, e.g. a set of possible characters.
- [RuleAny](http://kulibali.github.io/kiuatan/kiuatan-RuleAny/): matches any single input.
- [RuleSequence](http://kulibali.github.io/kiuatan/kiuatan-RuleSequence/): matches a sequence of sub-rules.  If any one of the sub-rules fails to match, the whole sequence fails.
- [RuleChoice](http://kulibali.github.io/kiuatan/kiuatan-RuleChoice/): tries to match one or more sub-rules in order, and succeeds on the first match.  A choice rule will not backtrack to a further choice if one has already succeeded.
- [RuleRepeat](http://kulibali.github.io/kiuatan/kiuatan-RuleRepeat/): matches a sub-rule repeatedly.  You can optionally specify a mininum number of times to match, and/or a maximum number of times.
- [RuleAnd](http://kulibali.github.io/kiuatan/kiuatan-RuleAnd/): Matches a sub-rule; if it succeeds, the rule itself succeeds, but the parse location does not advance.  Used for lookahead.
- [RuleNot](http://kulibali.github.io/kiuatan/kiuatan-RuleNot/): Matches a sub-rule; if it **fails**, the rule itself succeeds, but the parse location does not advance.

### [ParseLoc](http://kulibali.github.io/kiuatan/kiuatan-ParseLoc/)

A parse location holds a position in a linked list of sequences.  It is analogous to an index into an array.

### [ParseResult](http://kulibali.github.io/kiuatan/kiuatan-ParseResult/)

A parse result stores the results of a successful parse.  Parse results have a number of useful fields:

- `start`: the parse location in the input where the parse began.
- `next`: the parse location just past the end of where the parse ended.
- `children`: results obtained from sub-rules.

### [ParseState]()

A parse state manages a single instance of parsing some input using a rule.

## Example

The following example is a Pony program that implements a simple mathematical expression parser.

```pony

use "kiuatan"

actor Main
  """
  An example of very simple expression parser for the following grammar:

  Exp = Add
  Add = Add WS ('+' | '-') WS Mul
      | Mul
  Mul = Mul WS ('*' | '/') WS Num
      | Num
  Num = '(' WS Exp WS ')' WS
      | [0-9]+ WS
  """

  new create(env: Env) =>
    let exp = RuleSequence[U8]()
    let ws = RuleRepeat[U8](RuleClass[U8].from_iter(" \t".values()), 0)
    let num = RuleChoice[U8](
      [ RuleSequence[U8](
          [ RuleLiteral[U8]("(")
            ws
            exp
            ws
            RuleLiteral[U8](")")
          ])
      ])

```

