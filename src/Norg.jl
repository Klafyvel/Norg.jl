"""
Norg.jl provides a way to parse [Neorg](https://github.com/nvim-neorg/neorg)
files in pure Julia.
"""
module Norg

using Compat

include("tokens.jl")
include("scanners.jl")
include("tokenize.jl")
include("ast.jl")
include("match.jl")
include("parser.jl")
include("codegen.jl")

using .Tokens
using .Scanners
using .Tokenize
using .AST
using .Parser
using .Codegen

end
