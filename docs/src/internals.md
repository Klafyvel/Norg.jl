# Norg internals

This page describes the internals of Norg.jl and how it parses `.norg` files.

There are three main steps for turning Norg files into HTML (since it's the only supported target for now).

1. Tokenizing (identifying the different chunks of code)
2. Parsing (create an Abstract Syntax Tree, AST)
3. Code generation (turning the AST into HTML)

```@contents
Pages=["internals.md"]
```

# Notes on using Julia's dispatch system

Earlier Norg.jl would rely on Julia's type system, but that made the code
type-unstable. That's why I refactored it using a kind of enumeration to label
each token and node of the AST. I did not invent anything here, it comes
straight from [JuliaSyntax.jl](https://github.com/JuliaLang/JuliaSyntax.jl/)
super cool ideas. See [`Norg.Kinds`](@ref).

That does not mean that the native type system is not used. Rather, there are
some dispatch functions that are basically big `if` statements that dispatch a
given [`Norg.Kinds.Kind`](@ref) towards what's called a strategy in Norg.jl. Then the
native dispatch system can take the hand and dispatch towards the right method.
This allows making the code type-stable for the compiler and improves greatly
performances.

# Tokenization

The first step for parsing Norg documents is transforming the input string into
a more friendly array of token. A [`Norg.Tokens.Token`](@ref) labels a chunk of
text according to the significance the parser could give it. For example there
are token kinds for line endings, words, whitespaces, the `*` character... Note
that a token can span several characters. This is the case for words, but also
for whitespaces.

# Parsing

The second step consist in turning the array of tokens into an Abstract Syntax
Tree (AST). To do so, Norg.jl relies on two functions: [`Norg.Match.match_norg`](@ref) and
[`Norg.Parser.parse_norg`](@ref). The role of the former is to match a sequence of tokens to
a parsing strategy, while the latter does the actual parsing. For example, while
parsing a paragraph, if [`Norg.Match.match_norg`](@ref) encounters two tokens of kind
`LineEnding`, then it returns a closing match of kind `Paragraph`. It is then up
to `parse_norg` to properly close the current paragraph.

# Code generation

The third and last step consist in generating code output from the AST. Norg.jl
defines several code generation targets in the [`Norg.Codegen`](@ref) module. Code
generation is fairly simple, as it simply walks the AST and turn each node into
the correct output node. For example, a level one heading would be turned into
an HTML `<h1>` node when generating code for the [`HTMLTarget`](@ref) target.
