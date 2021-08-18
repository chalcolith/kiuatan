"""
# Kiuatan

Kiuatan ("horse" or "pony" in [Chinook Jargon](https://en.wikipedia.org/wiki/Chinook_Jargon#Chinook_Jargon_words_used_by_English-language_speakers)) is a library for building and running parsers in the [Pony](https://www.ponylang.org) programming language.

  - Kiuatan uses [Parsing Expression Grammar](https://en.wikipedia.org/wiki/Parsing_expression_grammar) semantics, which means:
    - Choices are ordered, i.e. the parser will always try to parse alternatives in the order they are declared.
    - Sequences are greedy, i.e. the parser will not backtrack from the end of a sequence.
    - You can use positive and negative lookahead that does not advance the match position to constrain greedy sequences.
    - Parsers do not backtrack from successful choices.
  - Kiuatan parsers are "packrat" parsers; they memoize intermediate results, resulting in linear-time parsing.
  - Parsers use Mederios et al's [algorithm](https://arxiv.org/abs/1207.0443) to handle unlimited left-recursion.

## Obtaining Kiuatan

### Corral

The easiest way to incorporate Kiuatan into your Pony project is to use Pony [Corral](https://github.com/ponylang/corral).  Once you have it installed, `cd` to your project's directory and type:

```bash
corral add github kulibali/kiuatan
```

This will add the library to your project.  You can then build your project with something like:

```bash
corral fetch
corral run -- ponyc .
```

### Git

You can clone and build Kiuatan directly from GitHub (you must have [Corral](https://github.com/ponylang/corral) in your `PATH`):

```bash
git clone https://github.com/kulibali/kiuatan.git
cd kiuatan
make && make test
```

To use Kiuatan in a project without [Corral](https://github.com/ponylang/corral) you will need to add `kiuatan/kiuatan` to your `PONYPATH` environment variable.

## Concepts

Kiuatan grammars can match over source sequences of any type that is

```pony
S: (Any #read & Equatable[S])
```

The most common source type will be [`U8`](https://stdlib.ponylang.org/builtin-U8/) for parsing UTF-8 text (note that you will need to handle converting UTF-8 into normalized Unicode yourself if necessary).

### Named Rules

A [`NamedRule`](/kiuatan-NamedRule) encapsulates and names a grammatical rule that encodes a PEG rule.  To create a rule, you provide a name, a body, and an optional [action](#action).  For example, the following rule will match either `one two three` or `one deux three`.

```pony
let rule =
  recover val
    let ws = NamedRule[U8]("WhiteSpace", Star[U8](Single[U8](" \t"), 1))
    NamedRule[U8]("OneTwoThree",
      Conj[U8](
        [ Literal[U8]("one")
          ws
          Disj[U8]([ Literal[U8]("two"); Literal[U8]("deux") ])
          ws
          Literal[U8]("three")
        ]))
  end
```

You can build the body of a rule from the following classes:

  - [Single](/kiuatan-Single): matches a single source item.  The constructor takes a set of possibilities to match.  If you provide an empty list, this rule will match any single item.
  - [Literal](kiuatan-Literal): matches a string of items.
  - [Conj](/kiuatan-Conj): matches a sequence of child rules.
  - [Disj](/kiuatan-Disj): matches one of a number of alternative child rules, in order.  If one of the alternatives matches, but an outer rule fails later, the parser will *not* backtrack to another alternative.
  - [Error](/kiuatan-Error): will trigger an error with the given message.
  - [Look](/kiuatan-Look): will attempt to match its child rule, but will *not* advance the match position.
  - [Neg](/kiuatan-Neg): will succeed if its child rule does *not* match, and will not advance the match position.
  - [Star](/kiuatan-Star): will match a number of repetitions of its child rule.  You can specify a minimum or maximum number of times to match.
  - [Bind](/kiuatan-Bind): will bind the result of its child rule to an existing variable.  See the [calc example](https://github.com/kulibali/kiuatan/blob/main/examples/calc/calc) for an example of how to use `Bind`.
  - [Condition](/kiuatan-Bind): will succeed only if its child matches and the given condition returns `true`.

#### Recursion

In order to allow recursive rules, you can create a rule with no body and set its body later using the [`set_body()`](/kiuatan-Rule/index.html#set_body) method:

```pony
// Add <- Add Op Num | Num
// Op <- [+-]
// Num <- [0-9]+
let rule: NamedRule[U8] val =
  recover val
    let add = NamedRule[U8]("Add", None)
    let num = NamedRule[U8]("Num", Star[U8](Single[U8]("0123456789"), 1))
    let op = NamedRule[U8]("Op", Single[U8]("+-"))
    let body = Disj[U8]([Conj[U8]([add; op; num]); num])
    add.set_body(body)
    add
  end
```

Note that Kiuatan can handle both direct and indirect left-recursion.

### Source

A [`Source`](/kiuatan-Source) is a sequence of sequences of your source type.  Internally this is represented as a linked list of sequences, called "segments".  The idea behind this is that you can swap out individual segments of text that your [`Parser`](/kiuatan-Parser) actor knows about, while maintaining the parse memo for the other segments.  This allows a text editor, for example, to handle localized changes without re-parsing the whole source file.

### Parser

A [`Parser`](/kiuatan-Parser) actor knows about the source you are parsing, and holds a memo of parsing results across parse attempts.

In order to attempt to parse a particular sequence (or sequence of segments) of items, create a Parser actor, giving it an initial source, and then call its [`parse`](/kiuatan-Parser/#parse) behaviour, passing a rule to use and a callback for when the parse either succeeds or fails:

```pony
  let segment = "one two three"
  let parser = Parser[U8]([segment])
  parser.parse(rule, {(result: Result[U8]) =>
    match result
    | let success: Success[U8] =>
      Debug.out("succeeded!")
    | let failure: Failure[U8] =>
      Debug.out("failed")
    end
  })
```

#### Updating Source

You can update a parser's source by calling its [`remove_segment`](/kiuatan-Parser/index.html#remove_segment) and [`insert_segment`](/kiuatan-Parser/index.html#insert_segment) behaviours.  The next time you initiate a parse, the parser's source will have been updated.

### Result

If a parse succeeds, the result will be of type [`Success`](/kiuatan-Success), which represents the concrete parse tree.  You can get details about the location of the match and results from child rules.

### Values

If you wish, you can build a more abstract parse tree using semantic [`Action`](/kiuatan-Action)s that you pass to rules.  These actions should return a "value" of your desired type.

### Data

If you wish, you can pass a data object of a specified type to the parser. This will be available to semantic actions.

```pony
let rule =
  recover val
    NamedRule[U8, String, String]("WithData",
      Literal[U8, String, String]("x",
        {(s, _, b) =>
          let str =
            recover
              let str': String ref = String
              for ch in s.start.values(s.next) do
                str'.push(ch)
              end
              str'.>append(s.data)
            end
          (str, b)
        }))
  end
```

"""
