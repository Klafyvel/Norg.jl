"""
This module defines the Abstract Syntax Trees (AST) associated with the norg format.
"""
module AST

using AbstractTrees

abstract type NodeData end

struct Node{T <: NodeData}
    children::Vector{Node}
    data::T
end
Node(data::T) where {T <: NodeData} = Node{T}(Node[], data)

AbstractTrees.children(t::Node) = t.children
AbstractTrees.nodevalue(t::Node) = t.data

struct NorgDocument <: NodeData end

struct Word <: NodeData
    value::String
end
struct Escape <: NodeData
    value::String
end

struct Paragraph <: NodeData end
abstract type TextContainer <: NodeData end
struct ParagraphSegment <: TextContainer end
abstract type MatchedInline <: TextContainer end

abstract type AttachedModifier <: MatchedInline end
struct Bold <: AttachedModifier end
struct Italic <: AttachedModifier end
struct Underline <: AttachedModifier end
struct Strikethrough <: AttachedModifier end
struct Spoiler <: AttachedModifier end
struct Superscript <: AttachedModifier end
struct Subscript <: AttachedModifier end
struct InlineCode <: AttachedModifier end

struct Link <: NodeData end
abstract type LinkLocation <: MatchedInline end
struct URLLocation <: LinkLocation end
struct LinkDescription <: MatchedInline end

abstract type DetachedModifier <: NodeData end
abstract type StructuralDetachedModifier <: DetachedModifier end
struct Heading{T} <: StructuralDetachedModifier
    title::Node{ParagraphSegment}
end
headinglevel(::Type{Heading{T}}) where {T} = T

const FirstClassNode = Union{Paragraph, StructuralDetachedModifier}

abstract type DelimitingModifier <: DetachedModifier end
struct WeakDelimitingModifier <: DelimitingModifier end
struct StrongDelimitingModifier <: DelimitingModifier end
struct HorizontalRule <: DelimitingModifier end

function printnode(io::IO, t::Node{ParagraphSegment})
    write(io, "ParagraphSegment(\"")
    for child in t.children
        if child isa Node{Word}
            write(io, child.data.value)
        else 
            printnode(io, child)
        end
    end
    write(io, "\")")
end
printnode(io::IO, n) = AbstractTrees.printnode(io,n)

Base.show(io::IO, t::Node) = print_tree(printnode, io, t)
Base.show(io::IO, t::Node{ParagraphSegment}) = printnode(io, t)
function AbstractTrees.print_tree(f::Function, io::IO, t::Node{ParagraphSegment}; kw...)
    write(io, "ParagraphSegment(\"")
    for child in t.children
        if child isa Node{Word}
            write(io, child.data.value)
        else 
            f(io, child)
        end
    end
    write(io, "\")\n")
end
end

