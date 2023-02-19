```@meta
CurrentModule = Norg
```

# Norg

Documentation for [Norg.jl](https://github.com/klafyvel/Norg.jl).

Norg.jl is a library to work with the [norg](https://github.com/nvim-neorg/norg-specs) file format used in [neorg](https://github.com/nvim-neorg/neorg). It currently implements the Layer 2 compatibility.

For a show-case of how the parser performs, please visit the [norg specification rendering page](1.0-specification/index.html). Note that the specification is not layer-2-friendly, so some parts just do not make sense **for now**.

```@contents
Pages = ["index.md"]
```

## General usage

There are currently two available code generation targets for Norg.jl: HTML and Pandoc JSON. Given a string to barse `s`, you can use:

```julia
norg(HTMLTarget(), s)
```

or

```julia
norg(JSONTarget(), s)
```

The sources for the Norg specification are available in an artifact of this package. Thus, you can generate an HTML version of the specification using:

```julia
using Norg

s = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end;
open("1.0-specification.html", "w") do f
    write(f, string(norg(HTMLTarget(), s)))
end
```

Since Pandoc JSON is also available, you can export to Pandoc JSON and feed it to pandoc:

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

## Advanced usage

You can also generate an Abstract Syntax Tree (AST) that implements AbstractTrees.jl interface using `norg`. See also the [`AST`](@ref) module.

```julia
norg(s)
```

## Public API

```@autodocs
Modules = [Norg]
```

## Inner API

The inner API is documented in the [Norg internals](internals/index.html) page.


