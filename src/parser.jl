"""
This module defines the [`Parser.parse`](@ref) function, which builds an AST from a token list.
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
        i, paragraph = parse_norg(AST.Paragraph, tokens, i)
        push!(paragraphs, paragraph)
    end
    i, AST.Node(paragraphs, AST.NorgDocument())
end

function parse_norg(::Type{AST.Paragraph}, tokens, i)
    segments = AST.Node[]
    while i <= lastindex(tokens)
        i, segment = parse_norg(AST.ParagraphSegment, tokens, i)
        push!(segments, segment)
        if i <= lastindex(tokens) && tokens[i] isa Token{Tokens.LineEnding}
            i = nextind(tokens, i)
            break
        end
    end
    i, AST.Node(segments, AST.Paragraph())
end

function parse_norg(::Type{AST.ParagraphSegment}, tokens, i)
    children = AST.Node[]
    last_token = nothing
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, AST.ParagraphSegment, tokens, i)
        @debug "paragrapgh segment loop" token i m
        if isnothing(m)
            i = nextind(tokens, i)
            break
        end
        i, node = parse_norg(m, tokens, i)
        if node isa Vector{AST.Node}
            append!(children, node)
            last_token = prevind(tokens, i)
        elseif !isnothing(node)
            @debug "node is nothing"
            push!(children, node)
            last_token = token
        end
    end
    i, AST.Node(children, AST.ParagraphSegment())
end

function parse_norg(::Type{T}, tokens, i) where {T <: AST.AttachedModifier}
    children = AST.Node[]
    opening_token = tokens[i]
    i = nextind(tokens, i)
    last_token = opening_token
    while i <= lastindex(tokens)
        token = tokens[i]
        if token isa Token{Tokens.LineEnding}
            break
        end
        m = match_norg(token, T, tokens, i)
        if isnothing(m)
            i = nextind(tokens, i)
            last_token = token
            break
        end
        i, node = parse_norg(m, tokens, i)
        if node isa Vector{AST.Node}
            append!(children, node)
            last_token = prevind(tokens, i)
        elseif !isnothing(node)
            push!(children, node)
            last_token = token
        end
    end
    if value(last_token) != value(opening_token) # we've been tricked in thincking we were in a modifier.
        pushfirst!(children, AST.Node(AST.Word(value(opening_token))))
        i, children
    elseif isempty(children)
        i, nothing
    else
        i, AST.Node(children, T())
    end
end

function parse_norg(::Type{AST.Escape}, tokens, i)
    begin
        next_i = nextind(tokens, i)
        if get(tokens, next_i, nothing) isa Union{Token{Tokens.Word}, Nothing}
            next_i, nothing
        else
            nextind(tokens, next_i), AST.Node(AST.Escape(value(tokens[next_i])))
        end
    end
end

function parse_norg(::Type{AST.Word}, tokens, i)
    nextind(tokens, i), AST.Node(AST.Word(value(tokens[i])))
end

export parse_norg
end
