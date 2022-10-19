"""
This module defines the Abstract Syntax Trees (AST) associated with the norg format.
"""
module AST

using AbstractTrees

using ..Kinds
using ..Tokens

# abstract type NodeData end

"""
An AST Node has a `kind` (e.g. `Bold`), can have children Nodes, and refer to
tokens in the token array.
"""
struct Node
    kind::Kind
    children::Vector{Node}
    start::Int
    stop::Int
end
Node(kind::Kind)= Node(kind, Node[], 1, 1)

struct NorgDocument
    nodes::Vector{Node}
    tokens::Vector{Token}
end

Kinds.kind(node::Node) = node.kind
start(node::Node) = node.start
stop(node::Node) = node.stop

AbstractTrees.children(node::Node) = node.children
AbstractTrees.nodevalue(node::Node) = (kind(node), start(node), stop(node))
AbstractTrees.children(node::NorgDocument) = node.nodes
AbstractTrees.nodevalue(node::NorgDocument) = "NorgDocument"
Base.show(io::IO, t::Node) = print_tree(io, t)

function Base.show(io::IO, t::NorgDocument)
    print_tree(io, t) do io, node
        if node isa NorgDocument
            print(io, "NorgDocument")
        elseif is_leaf(node)
            print(io, join(value.(t.tokens[start(node):stop(node)])))
        else
            print(io, repr(nodevalue(node)))
        end
    end
end

Kinds.is_leaf(node::Node) = is_leaf(kind(node))
Kinds.is_matched_inline(node::Node) = is_matched_inline(kind(node))
Kinds.is_attached_modifier(node::Node) = is_attached_modifier(kind(node))
Kinds.is_link_location(node::Node) = is_link_location(kind(node))
Kinds.is_detached_modifier(node::Node) = is_detached_modifier(kind(node))
Kinds.is_delimiting_modifier(node::Node) = is_delimiting_modifier(kind(node))
Kinds.is_nestable(node::Node) = is_nestable(kind(node))
Kinds.is_heading(node::Node) = is_heading(kind(node))
Kinds.is_unordered_list(node::Node) = is_unordered_list(kind(node))
Kinds.is_ordered_list(node::Node) = is_ordered_list(kind(node))
Kinds.is_quote(node::Node) = is_quote(kind(node))
is_first_class_node(k::Kind) = k ∈ [K"Paragraph", K"Verbatim"] || is_detached_modifier(k) || is_nestable(k) || is_heading(k)
is_first_class_node(node::Node) = is_first_class_node(kind(node))

heading_level(node::Node) = heading_level(kind(node))
function heading_level(k::Kind)
    if !is_heading(k)
        error("Asking for the heading level of a non-heading k")
    end
    if k == K"Heading1"
        1
    elseif k == K"Heading2"
        2
    elseif k == K"Heading3"
        3
    elseif k == K"Heading4"
        4
    elseif k == K"Heading5"
        5
    elseif k == K"Heading6"
        6
    else
        error("No matching Heading kind found.")
    end
end
function heading_level(level::Int)
    if level <= 1
        K"Heading1"
    elseif level == 2
        K"Heading2"
    elseif level == 3
        K"Heading3"
    elseif level == 3
        K"Heading3"
    elseif level == 4
        K"Heading4"
    elseif level == 5
        K"Heading5"
    else 
        K"Heading6"
    end
end

unordered_list_level(node::Node) = unordered_list_level(kind(node))
function unordered_list_level(k::Kind)
    if !is_unordered_list(k)
        error("Asking for the unordered-list level of a non-unordered-list k")
    end
    if k == K"UnorderedList1"
        1
    elseif k == K"UnorderedList2"
        2
    elseif k == K"UnorderedList3"
        3
    elseif k == K"UnorderedList4"
        4
    elseif k == K"UnorderedList5"
        5
    elseif k == K"UnorderedList6"
        6
    else
        error("No matching UnorderedList kind found.")
    end
end
function unordered_list_level(level::Int)
    if level <= 1
        K"UnorderedList1"
    elseif level == 2
        K"UnorderedList2"
    elseif level == 3
        K"UnorderedList3"
    elseif level == 3
        K"UnorderedList3"
    elseif level == 4
        K"UnorderedList4"
    elseif level == 5
        K"UnorderedList5"
    else 
        K"UnorderedList6"
    end
end

ordered_list_level(node::Node) = ordered_list_level(kind(node))
function ordered_list_level(k::Kind)
    if !is_ordered_list(k)
        error("Asking for the ordered-list level of a non-ordered-list k")
    end
    if k == K"OrderedList1"
        1
    elseif k == K"OrderedList2"
        2
    elseif k == K"OrderedList3"
        3
    elseif k == K"OrderedList4"
        4
    elseif k == K"OrderedList5"
        5
    elseif k == K"OrderedList6"
        6
    else
        error("No matching OrderedList kind found.")
    end
end
function ordered_list_level(level::Int)
    if level <= 1
        K"OrderedList1"
    elseif level == 2
        K"OrderedList2"
    elseif level == 3
        K"OrderedList3"
    elseif level == 3
        K"OrderedList3"
    elseif level == 4
        K"OrderedList4"
    elseif level == 5
        K"OrderedList5"
    else 
        K"OrderedList6"
    end
end

quote_level(node::Node) = quote_level(kind(node))
function quote_level(k::Kind)
    if !is_quote(k)
        error("Asking for the quote level of a non-quote k")
    end
    if k == K"Quote1"
        1
    elseif k == K"Quote2"
        2
    elseif k == K"Quote3"
        3
    elseif k == K"Quote4"
        4
    elseif k == K"Quote5"
        5
    elseif k == K"Quote6"
        6
    else
        error("No matching Quote kind found.")
    end
end
function quote_level(level::Int)
    if level <= 1
        K"Quote1"
    elseif level == 2
        K"Quote2"
    elseif level == 3
        K"Quote3"
    elseif level == 3
        K"Quote3"
    elseif level == 4
        K"Quote4"
    elseif level == 5
        K"Quote5"
    else 
        K"Quote6"
    end
end
function nestable_level(k::Kind)
    if !is_nestable(k)
        error("Asking for the nestable level of a non-nestable k")
    end
    if is_unordered_list(k)
        unordered_list_level(k)
    elseif is_ordered_list(k)
        ordered_list_level(k)
    elseif is_quote(k)
        quote_level(k)
    else
        error("Nestable nodess ill-defined")
    end
end

export is_first_class_node, heading_level, unordered_list_level, ordered_list_level, quote_level, nestable_level

#= struct Word <: NodeData
    value::String
end
Word(c::Char) = Word(string(c))
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
struct URLLocation <: LinkLocation
    target::String
end
struct LineNumberLocation <: LinkLocation
    target::Int
end
struct DetachedModifierLocation <: LinkLocation
    target::String
    targetlevel::Int
end
abstract type CustomDetachedModifierLocation <: LinkLocation end
struct MagicLocation <: CustomDetachedModifierLocation
    target::String
end
FileLinkableLocationSubTarget = Union{Node{LineNumberLocation}, Nothing}
struct FileLinkableLocation <: CustomDetachedModifierLocation
    use_neorg_root::Bool
    target::String
    subtarget::FileLinkableLocationSubTarget
end
FileLocationSubTarget = Union{Node{LineNumberLocation},
                              Node{DetachedModifierLocation},
                              Node{MagicLocation}, Nothing}
struct FileLocation <: LinkLocation
    use_neorg_root::Bool
    target::String
    subtarget::FileLocationSubTarget
end
struct LinkDescription <: MatchedInline end
struct Anchor <: NodeData
    has_definition::Any
end

abstract type DetachedModifier <: NodeData end
abstract type StructuralDetachedModifier <: DetachedModifier end
struct Heading{T} <: StructuralDetachedModifier
    title::Node{ParagraphSegment}
end
headinglevel(::Type{Heading{T}}) where {T} = T
headinglevel(::Heading{T}) where {T} = T

abstract type DelimitingModifier <: DetachedModifier end
struct WeakDelimitingModifier <: DelimitingModifier end
struct StrongDelimitingModifier <: DelimitingModifier end
struct HorizontalRule <: DelimitingModifier end

abstract type NestableDetachedModifier{T} <: DetachedModifier end
struct UnorderedList{T} <: NestableDetachedModifier{T} end
struct OrderedList{T} <: NestableDetachedModifier{T} end
struct Quote{T} <: NestableDetachedModifier{T} end
struct NestableItem <: NodeData end
nestlevel(::Type{<:NestableDetachedModifier{T}}) where {T} = T

abstract type Tag <: NodeData end
abstract type RangedTag <: Tag end
struct Verbatim <: RangedTag
    tag::String
    subtag::Union{String, Nothing}
    parameters::Vector{String}
end
struct VerbatimBody <: NodeData
    value::String
end =#


end
