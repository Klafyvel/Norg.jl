module Codegen
using ..AST

abstract type CodegenTarget end

function codegen end
codegen(t::Type{T}, ast) where {T <: CodegenTarget} = codegen(t(), ast)

include("codegen/html.jl")
using .HTMLCodegen

export codegen, HTMLTarget

end
