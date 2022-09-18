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
    value::Any
end
struct Escape <: NodeData
    value::Any
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

Base.show(io::IO, t::Node{NorgDocument}) = print_tree(io, t)
end
