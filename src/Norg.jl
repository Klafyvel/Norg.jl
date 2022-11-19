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

"""
The root directory of the Norg specification.
"""
const NORG_SPEC_ROOT = let
    r = artifact"norg-specs-main"
    joinpath(r, first(readdir(r)))
end
"""
Path to the Norg specification.
"""
const NORG_SPEC_PATH = joinpath(NORG_SPEC_ROOT, "1.0-specification.norg")
"""
Path to the Norg standard library.
"""
const NORG_STDLIB_PATH = joinpath(NORG_SPEC_ROOT, "stdlib.norg")
"""
Path to the Norg semantics specification.
"""
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

"""
    parse(HTMLTarget(), s)
    parse(JSONTarget(), s)

Parse a Norg string to the specified targets.

See also: [`HTMLTarget`](@ref), [`JSONTarget`](@ref)
"""
Base.parse(::Type{T}, s) where {T <: Codegen.CodegenTarget} = codegen(T(), parse_norg(tokenize(s)))
Base.parse(t::T, s) where {T <: Codegen.CodegenTarget} = codegen(t, parse_norg(tokenize(s)))


"""
Easily parse Norg string to an AST

julia> norg"* Norg Header 1 Example"
<div class="norg"><section id="section-h1-norg-header-1-example"><h1 id="h1-
norg-header-1-example">Norg Header 1 Example</h1></section></div>
"""
macro norg_str(s, t ...)
	parse(AST.NorgDocument, s)
end

function Base.show(io::IO, ::MIME"text/html", ast::AST.NorgDocument)
    print(io, codegen(HTMLTarget(), ast))
end

export HTMLTarget, JSONTarget
export @norg_str

end
