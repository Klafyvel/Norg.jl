module Codegen
using ..AST
using ..Strategies
using ..Kinds

abstract type CodegenTarget end

function codegen end
codegen(t::Type{T}, ast::AST.NorgDocument) where {T <: CodegenTarget} = codegen(t(), ast)

include("codegen/html.jl")
using .HTMLCodegen

export codegen, HTMLTarget

end
