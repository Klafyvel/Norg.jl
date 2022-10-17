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

using Compat

include("kind.jl")
include("tokens.jl")
include("scanners.jl")
include("tokenize.jl")
# include("ast.jl")
# include("match/match.jl")
# include("parser/parser.jl")
# include("codegen.jl")

using .Kinds
using .Tokens
using .Scanners
using .Tokenize
# using .AST
# using .Parser
# using .Codegen
#
# Base.parse(::Type{HTMLTarget}, s) = codegen(HTMLTarget, parse_norg(tokenize(s)))
#
# export HTMLTarget

end
