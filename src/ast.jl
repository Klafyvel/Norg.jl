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
end

"""
Type of nodes that can be direct child of a NorgDocument
"""
const FirstClassNode = Union{Paragraph, StructuralDetachedModifier,
                             NestableDetachedModifier, StrongDelimitingModifier,
                             Heading, Tag}

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
printnode(io::IO, n) = AbstractTrees.printnode(io, n)

Base.show(io::IO, t::Node) = print_tree(printnode, io, t)
Base.show(io::IO, t::Node{ParagraphSegment}) = printnode(io, t)
function AbstractTrees.print_tree(f::Function, io::IO,
                                  t::Node{ParagraphSegment}; kw...)
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
