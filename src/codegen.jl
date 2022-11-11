"""
This module holds all the code generation targets, as well as some generic utilities
to help with code generation.
"""
module Codegen
using AbstractTrees

using ..AST
using ..Strategies
using ..Kinds
using ..Tokens

abstract type CodegenTarget end

"""
    idify(text)

Make some text suitable for using it as an id in a document.
"""
function idify(text)
    words = map(lowercase, split(text, r"\W+"))
    join(filter(!isempty, words), '-')
end

"""
    textify(ast, node)

Return the raw text associated with a node.
"""
function textify(ast, node)
    if is_leaf(node)
        AST.litteral(ast, node)
    else
        join(textify(ast, c) for c in children(node))
    end
end

"""
    codegen(T, ast)
    codegen(target, ast)

Do code generation for a given [`AST.NorgDocument`](@ref) to a given target.
"""
function codegen end
codegen(t::Type{T}, ast::AST.NorgDocument) where {T <: CodegenTarget} = codegen(t(), ast)

function codegen(t::T, strategy::S, ast, node) where {T <: CodegenTarget, S <: Strategies.Strategy}
    error("Unimplemented codegen strategy $strategy for $t.")
end

function codegen(t::T, ast::AST.NorgDocument, node::AST.Node) where {T <: CodegenTarget}
    if kind(node) == K"Paragraph"
        codegen(t, Paragraph(), ast, node)        
    elseif kind(node) == K"ParagraphSegment"
        codegen(t, ParagraphSegment(), ast, node)
    elseif kind(node) == K"Bold"
        codegen(t, Bold(), ast, node)
    elseif kind(node) == K"Italic"
        codegen(t, Italic(), ast, node)
    elseif kind(node) == K"Underline"
        codegen(t, Underline(), ast, node)
    elseif kind(node) == K"Strikethrough"
        codegen(t, Strikethrough(), ast, node)
    elseif kind(node) == K"Spoiler"
        codegen(t, Spoiler(), ast, node)
    elseif kind(node) == K"Superscript"
        codegen(t, Superscript(), ast, node)
    elseif kind(node) == K"Subscript"
        codegen(t, Subscript(), ast, node)
    elseif kind(node) == K"InlineCode"
        codegen(t, InlineCode(), ast, node)
    elseif kind(node) == K"WordNode"
        codegen(t, Word(), ast, node)
    elseif kind(node) == K"Escape"
        codegen(t, Escape(), ast, node)
    elseif kind(node) == K"Link"
        codegen(t, Link(), ast, node)
    elseif kind(node) == K"URLLocation"
        codegen(t, URLLocation(), ast, node)
    elseif kind(node) == K"LineNumberLocation"
        codegen(t, LineNumberLocation(), ast, node)
    elseif kind(node) == K"DetachedModifierLocation"
        codegen(t, DetachedModifierLocation(), ast, node)
    elseif kind(node) == K"MagicLocation"
        codegen(t, MagicLocation(), ast, node)
    elseif kind(node) == K"FileLocation"
        codegen(t, FileLocation(), ast, node)
    elseif kind(node) == K"NorgFileLocation"
        codegen(t, NorgFileLocation(), ast, node)
    elseif kind(node) == K"LinkDescription"
        codegen(t, LinkDescription(), ast, node)
    elseif kind(node) == K"Anchor"
        codegen(t, Anchor(), ast, node)
    elseif is_heading(node)
        codegen(t, Heading(), ast, node)
    elseif kind(node) == K"StrongDelimitingModifier"
        codegen(t, StrongDelimiter(), ast, node)
    elseif kind(node) == K"WeakDelimitingModifier"
        codegen(t, WeakDelimiter(), ast, node)
    elseif kind(node) == K"HorizontalRule"
        codegen(t, HorizontalRule(), ast, node)
    elseif is_unordered_list(node)
        codegen(t, UnorderedList(), ast, node)
    elseif is_ordered_list(node)
        codegen(t, OrderedList(), ast, node)
    elseif is_quote(node)
        codegen(t, Quote(), ast, node)
    elseif kind(node) == K"NestableItem"
        codegen(t, NestableItem(), ast, node)
    elseif kind(node) == K"Verbatim"
        codegen(t, Verbatim(), ast, node)
    else
        t_start = ast.tokens[AST.start(node)]
        t_stop = ast.tokens[AST.stop(node)]
        error("""HTML codegen got an unhandled node type: $(kind(node)). 
        Faulty node starts at line $(line(t_start)), col. $(char(t_start))
        and stops at line $(line(t_stop)), col. $(char(t_stop))."""
        )
    end
end


include("codegen/html.jl")
include("codegen/json.jl")
using .HTMLCodegen
using .JSONCodegen

export codegen, HTMLTarget, JSONTarget

end
