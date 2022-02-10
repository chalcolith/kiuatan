# Kiuatan

![CI](https://github.com/kulibali/kiuatan/workflows/CI/badge.svg)

Kiuatan ("horse" or "pony" in [Chinook Jargon](https://en.wikipedia.org/wiki/Chinook_Jargon#Chinook_Jargon_words_used_by_English-language_speakers)) is a library for building and running parsers in the [Pony](https://www.ponylang.org) programming language.

- Kiuatan uses [Parsing Expression Grammar](https://en.wikipedia.org/wiki/Parsing_expression_grammar) semantics, which means:
- Choices are ordered, i.e. the parser will always try to parse alternatives in the order they are declared.
  - Sequences are greedy, i.e. the parser will not backtrack from the end of a sequence.
  - You can use positive and negative lookahead that does not advance the match position to constrain greedy sequences.
  - Parsers do not backtrack from successful choices.
- Kiuatan parsers are "packrat" parsers; they memoize intermediate results, resulting in linear-time parsing.
- Parsers use Mederios et al's [algorithm](https://arxiv.org/abs/1207.0443) to handle unlimited left-recursion.

Further [documentation is here](https://kulibali.github.io/kiuatan/kiuatan--index/).

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

You can clone and build Kiuatan directly from GitHub:

```bash
git clone https://github.com/kulibali/kiuatan.git
cd kiuatan
make test
```

To use Kiuatan in a project you will need to add `kiuatan/kiuatan` to your `PONYPATH` environment variable.

## Documentation

[Documentation is here](https://kulibali.github.io/kiuatan/kiuatan--index/).

## Example

See the [calc example](https://github.com/kulibali/kiuatan/blob/main/examples/calc/calc) for a sample of how to define and use a grammar for Kiuatan.
