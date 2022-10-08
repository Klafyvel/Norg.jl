# Norg

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://klafyvel.github.io/Norg.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://klafyvel.github.io/Norg.jl/dev/)
[![Build Status](https://github.com/klafyvel/Norg.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/klafyvel/Norg.jl/actions/workflows/CI.yml?query=branch%3Amain)

Norg.jl is a library to parse the [norg file format](https://github.com/nvim-neorg/norg-specs) 
used in [NeoVim's neorg](https://github.com/nvim-neorg/neorg).

## What can it do ?

For now the layer 1 compatibility is implemented, and there is code generation for html targets.

```julia
julia> using Norg, Hyperscript

julia> s = """
       Hi ! I am a Norg document. For now only /basic/ *markup* is !implemented!.
       That should not prevent you from *,!nesting!, ^the^ /good/ `stuff`*

       You can of course make paragraphs, you -nerd- /beautiful/ nerd.

       We also can use links : {https://example.com}

       But it's easier to read if you use a link description, as in this link towards {https://klafyvel.me}[my *website*] !
       """;

julia> parse(HTMLTarget, s) |> Pretty
# pretty HTML prints there, but have a look at its rendering below
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

## Roadmap

```
  - (-) Layer 2 support
  -- (x) Headings
  -- (x) Nestable Detached Modifiers (quotes and lists)
  -- (-) Linkables (everything except timestamps, wiki links) and anchors
  --- (x) file location
  --- (x) line number
  --- (x) detached modifier
  --- (x) custom detached modifiers
  --- ( ) anchors
  -- (x) Verbatim ranged tags
  -- (x) Delimiting modifiers
  #waiting.for Layer 2 support
  - ( ) Layer 3 Support
  -- ( ) Timestamp links and inline link targets
  -- ( ) Carryover tags
  -- ( ) Detached modifier extensions
  -- ( ) Range-able detached modifiers, excluding table cells
  -- ( ) Trailing modifiers
  -- ( ) Link modifiers
  #waiting.for Layer 3 support
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
  -- ( ) HTML
  -- ( ) Markdown
  -- ( ) Pandoc JSON
  -- ( ) Julia Terminal display using julia's nice features such as `printstyled` and others.
  -- ( ) Norg
  #waiting.for Layer 4 support
  - ( ) Consume pandoc JSON to create a Norg AST.
  #waiting.for Layer 4 support
  - ( ) Export CLI utility
  #contexts someday
  - ( ) Allow Franklin.jl to use Norg file format, because NeoVim+Julia = <3
  #contexts someday
  - ( ) Documenter.jl plugin
  #contexts someday
  - ( ) Term.jl plugin
```

## Installation 

The package is not yet registered.

```julia
] add https://github.com/Klafyvel/Norg.jl
```
