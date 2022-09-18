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
```

## End goal

* Parse Norg files,
* Terminal display using julia's nice features such as `printstyled` and others.
* Output HTML,
* Output Markdown,
* Add a FileIO interface,
* Allow Franklin.jl to use Norg file format, because NeoVim+Julia = <3
* Documenter.jl plugin ?
* Term.jl plugin ?
