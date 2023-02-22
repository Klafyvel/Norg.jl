# Norg

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://klafyvel.github.io/Norg.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://klafyvel.github.io/Norg.jl/dev/)
[![Build Status](https://github.com/klafyvel/Norg.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/klafyvel/Norg.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Test Coverage](https://codecov.io/gh/Klafyvel/Norg.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Klafyvel/Norg.jl)

Norg.jl is a library to parse the [norg file format](https://github.com/nvim-neorg/norg-specs) 
used in [NeoVim's neorg](https://github.com/nvim-neorg/neorg).

This is heavily work in progress, so expect breaking changes. Meanwhile, I'd be really happy if you could try Norg.jl and tell me if you find unexpected behaviours. 

## Installation 

The package is registered.

```julia
]add Norg
```

If you want the latest dev version:

```julia
]add https://github.com/Klafyvel/Norg.jl
```

## What can it do ?

For now layer 3 compatibility is implemented in the parser, and there is code generation for html and pandoc JSON targets. There is no semantic analysis yet, which for example means that links to line number or using the `#` target syntax are poorly handled in code generation.

```julia
julia> using Norg

julia> s = """
       Hi ! I am a Norg document. For now only /basic/ *markup* is !implemented!.
       That should not prevent you from *,!nesting!, ^the^ /good/ `stuff`*

       You can of course make paragraphs, you -nerd- /beautiful/ nerd.

       We also can use links : {https://example.com}

       But it's easier to read if you use a link description, as in this link towards {https://klafyvel.me}[my *website*] !
       """;

julia> norg(HTMLTarget(), s)
# pretty HTML prints there, but have a look at its rendering below

julia> norg"Neorg also has a string macro that can be used in Pluto"
```


<div class="norg">
  <p>Hi &#33; I am a Norg document. For now only
    <i>basic</i>
    <b>markup</b> is
    <span class="spoiler">implemented</span>.
    <br />That should not prevent you from *
    <sub>
      <span class="spoiler">nesting</span>
    </sub>
    <sup>the</sup>
    <i>good</i>
    <code>stuff</code>*
  </p>
  <p>You can of course make paragraphs, you
    <del>nerd</del>
    <i>beautiful</i> nerd.
  </p>
  <p>We also can use links :
    <a href="https://example.com">https://example.com</a>
  </p>
  <p>But it&#39;s easier to read if you use a link description, as in this link towards
    <a href="https://klafyvel.me">my
      <b>website</b>
    </a> &#33;
  </p>
</div>

Note that you can parse the entire Norg specification just like that:
```julia
using Norg

s = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end;
open("1.0-specification.html", "w") do f
    write(f, string(norg(HTMLTarget(), s)))
end
```

Norg.jl is also capable of outputing Pandoc JSON, allowing you to feed your 
Norg files to pandoc!

```julia
import JSON
open("1.0-specification.json", "w") do f
  JSON.print(f, norg(JSONTarget(), s), 2)
end;
```

You can then invoke Pandoc as follow:
```bash
pandoc -f json -t markdown 1.0-specification.json -o 1.0-specification.md
```

## Roadmap

```
  - (x) Layer 1 support
  - (x) Layer 2 support
  - (x) Layer 3 Support
  - ( ) Layer 4 support
  -- ( ) Standard Ranged Tags
  -- ( ) Table cells
  -- ( ) Free-form attached modifiers
  -- ( ) Intersection modifiers
  -- ( ) Attached modifier extensions
  -- ( ) Inline mathematics and variable attached modifiers
  #waiting.for Layer 4 support
  - ( ) Layer 5 support
  -- ( ) Interpretation/Execution of macro tags
  -- ( ) Semantic understanding/execution of carryover tags
  -- ( ) Evaluation of `@code` blocs for the NIP language (if they are marked with `#eval`)
  #waiting.for Layer 4 support
  - ( ) FileIO.jl integration
  - ( ) Various code generation
  -- (-) HTML
  --- (x) Layer 1 support
  --- (x) Layer 2 support
  --- (x) Layer 3 support
  --- ( ) Layer 4 support
  --- ( ) Layer 5 support
  -- ( ) Markdown
  --- ( ) Layer 1 support
  --- ( ) Layer 2 support
  --- ( ) Layer 3 support
  --- ( ) Layer 4 support
  --- ( ) Layer 5 support
  -- (-) Pandoc JSON
  --- (x) Layer 1 support
  --- (x) Layer 2 support
  --- (x) Layer 3 support
  --- ( ) Layer 4 support
  --- ( ) Layer 5 support
  -- ( ) Julia Terminal display using julia's nice features such as `printstyled` and others.
  --- ( ) Layer 1 support
  --- ( ) Layer 2 support
  --- ( ) Layer 3 support
  --- ( ) Layer 4 support
  --- ( ) Layer 5 support
  -- ( ) Norg
  --- ( ) Layer 1 support
  --- ( ) Layer 2 support
  --- ( ) Layer 3 support
  --- ( ) Layer 4 support
  --- ( ) Layer 5 support
  #waiting.for Layer 4 support
  - ( ) Consume pandoc JSON to create a Norg AST.
  #waiting.for Layer 4 support
  - ( ) Export CLI utility
  #contexts someday
  - ( ) Allow Franklin.jl to use Norg file format, because NeoVim+Julia = <3
  #contexts someday
  - ( ) Documenter.jl plugin
```

## Under the hood

There are three main steps for turning Norg files into HTML (since it's the only supported target for now).

1. Tokenizing (identifying the different chunks of code)
2. Parsing (create an Abstract Syntax Tree, AST)
3. Code generation (turning the AST into HTML)

Earlier Norg.jl would rely on Julia's type system, but that made the code type-unstable. That's why I refactored it using a kind of enumeration to label each token and node of the AST. I did not invent anything here, it comes straight from [JuliaSyntax.jl](https://github.com/JuliaLang/JuliaSyntax.jl/) super cool ideas.
