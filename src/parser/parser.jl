"""
This module defines the [`Norg.Parser.parse_norg`](@ref) function, which builds
an AST from a token list.

The role of [`Norg.Parser.parse`](@ref) is to *consume* tokens. To do so, it
relies on [`Norg.Match.match_norg`](@ref) to take decisions on how to consume
tokens.
"""
module Parser

using ..Tokens
using ..Tokenize
using ..AST
using ..Match

"""
    parse(AST.NorgDocument, s)

Produce an [`AST.NorgDocument`](@ref) from a string `s`. Calls [`Tokenize.tokenize`](@ref).
"""
function Base.parse(::Type{AST.NorgDocument}, s::AbstractString)
    parse_norg(Tokenize.tokenize(s))
end

"""
    consume_until(T, tokens, i)

Consume tokens until a token of type T is encountered, or final token is reached.
"""
function consume_until(::Type{T}, tokens, i) where {T <: Tokens.TokenType}
    token = get(tokens, i, nothing)
    while !isnothing(token) && !(token isa Token{T})
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if token isa Token{T}
        i = nextind(tokens, i)
    end
    i
end

"""
    parse_norg(nodetype, tokens, i)

Try to parse the `tokens` sequence starting at index `i` as a `nodetype`.
"""
function parse_norg end

"""
    parse_norg(tokens)

Try to parse the `tokens` sequence as an [`AST.NorgDocument`](@ref) starting
from the begining of the sequence.
"""
function parse_norg(tokens)
    last(parse_norg(AST.NorgDocument, tokens, firstindex(tokens)))
end

function parse_norg(::Type{AST.NorgDocument}, tokens, i)
    paragraphs = AST.Node[]
    while i <= lastindex(tokens)
        i, paragraph = parse_norg(AST.FirstClassNode, tokens, i,
                                  [AST.NorgDocument])
        if !isnothing(paragraph)
            push!(paragraphs, paragraph)
        end
    end
    i, AST.Node(paragraphs, AST.NorgDocument())
end

function parse_norg(::Type{AST.FirstClassNode}, tokens, i, parents)
    token = get(tokens, i, nothing)
    m = match_norg(token, parents, tokens, i)
    if isclosing(m)
        @error "Closing token when parsing first class node" token m parents
        error("This is a bug, please report it along with the text you are trying to parse.")
    elseif iscontinue(m)
        return nextind(tokens, i), nothing
    end
    to_parse = matched(m)
    if to_parse <: AST.DelimitingModifier
        i = consume_until(Tokens.LineEnding, tokens, i)
        i, AST.Node(AST.Node[], to_parse())
    elseif to_parse <: AST.FirstClassNode
        parse_norg(to_parse, tokens, i, parents)
    else
        parse_norg(AST.Paragraph, tokens, i, parents)
    end
end

function parse_norg(::Type{AST.Paragraph}, tokens, i, parents)
    segments = AST.Node[]
    m = Match.MatchClosing{AST.Paragraph}()
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.Paragraph, parents...], tokens, i)
        @debug "Paragraph loop" token m
        if isclosing(m)
            break
        elseif iscontinue(m)
            i = nextind(tokens, i)
            continue
        end
        to_parse = matched(m)
        if to_parse <: AST.DelimitingModifier
            break
        elseif to_parse <: AST.Heading
            break
        else
            i, segment = parse_norg(AST.ParagraphSegment, tokens, i,
                                    [AST.Paragraph, parents...])
            if segment isa Vector
                append!(segments, segment)
            else
                push!(segments, segment)
            end
        end
    end
    if isclosing(m) && matched(m) == AST.Paragraph && m.consume
        i = nextind(tokens, i)
    end
    i, AST.Node(segments, AST.Paragraph())
end

function parse_norg(::Type{AST.ParagraphSegment}, tokens, i, parents)
    children = AST.Node[]
    m = Match.MatchClosing{AST.ParagraphSegment}()
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.ParagraphSegment, parents...], tokens, i)
        if isclosing(m)
            break
        end
        to_parse = matched(m)
        if to_parse <: AST.DelimitingModifier
            break
        elseif to_parse <: AST.Heading
            break
        end
        i, node = parse_norg(to_parse, tokens, i,
                             [AST.ParagraphSegment, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        elseif !isnothing(node)
            push!(children, node)
        end
    end
    if isclosing(m) && matched(m) == AST.ParagraphSegment && m.consume
        i = nextind(tokens, i)
    end
    if matched(m) == AST.WeakDelimitingModifier
        i,
        [
            AST.Node(children, AST.ParagraphSegment()),
            AST.Node(AST.Node[], AST.WeakDelimitingModifier()),
        ]
    else
        i, AST.Node(children, AST.ParagraphSegment())
    end
end

function parse_norg(::Type{AST.Escape}, tokens, i, parents)
    next_i = nextind(tokens, i)
    if get(tokens, next_i, nothing) isa Union{Token{Tokens.Word}, Nothing}
        next_i, nothing
    else
        nextind(tokens, next_i), AST.Node(AST.Escape(value(tokens[next_i])))
    end
end

include("attachedmodifier.jl")
include("link.jl")
include("structuralmodifier.jl")
include("verbatim.jl")
include("nestablemodifier.jl")

function parse_norg(::Type{AST.Word}, tokens, i, parents)
    nextind(tokens, i), AST.Node(AST.Word(value(tokens[i])))
end

export parse_norg
end
