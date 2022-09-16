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
include("parser.jl")

using .Tokens, .Scanners
# Write your package code here.

end
