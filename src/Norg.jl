"""
Norg.jl provides a way to parse [Neorg](https://github.com/nvim-neorg/neorg)
files in pure Julia.

It overloads `Base.parse` with custom targets. So far the only available target
is `HTMLTarget`.

Example usage :

```julia
using Norg, Hyperscript
parse(HTMLTarget, "Read {https://github.com/nvim-neorg/norg-specs}[the spec !]")
```
"""
module Norg

using Pkg.Artifacts

const NORG_SPEC_ROOT = joinpath(artifact"norg-specs", "nvim-neorg-norg-specs-f489385")
const NORG_SPEC_PATH = joinpath(NORG_SPEC_ROOT, "1.0-specification.norg")
const NORG_STDLIB_PATH = joinpath(NORG_SPEC_ROOT, "stdlib.norg")
const NORG_SEMANTICS_PATH = joinpath(NORG_SPEC_ROOT, "1.0-semantics.norg")

include("kind.jl")
include("strategy.jl")
include("tokens.jl")
include("scanners.jl")
include("tokenize.jl")
include("ast.jl")
include("match/match.jl")
include("parser/parser.jl")
include("codegen.jl")

using .Kinds
using .Tokens
using .Scanners
using .Tokenize
using .AST
using .Parser
using .Codegen

Base.parse(::Type{T}, s) where {T <: Codegen.CodegenTarget} = codegen(T(), parse_norg(tokenize(s)))
Base.parse(t::T, s) where {T <: Codegen.CodegenTarget} = codegen(t, parse_norg(tokenize(s)))

export HTMLTarget, JSONTarget

end
