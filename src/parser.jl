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
        i, paragraph = parse_norg(AST.Paragraph, tokens, i, [AST.NorgDocument])
        push!(paragraphs, paragraph)
    end
    i, AST.Node(paragraphs, AST.NorgDocument())
end

function parse_norg(::Type{AST.Paragraph}, tokens, i, parents)
    segments = AST.Node[]
    while i <= lastindex(tokens)
        i, segment = parse_norg(AST.ParagraphSegment, tokens, i,
                                [AST.Paragraph, parents...])
        push!(segments, segment)
        if i <= lastindex(tokens) && tokens[i] isa Token{Tokens.LineEnding}
            i = nextind(tokens, i)
            break
        end
    end
    i, AST.Node(segments, AST.Paragraph())
end

function parse_norg(::Type{AST.ParagraphSegment}, tokens, i, parents)
    children = AST.Node[]
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.ParagraphSegment, parents...], tokens, i)
        @debug "paragrapgh segment loop" token i m
        if isnothing(m)
            i = nextind(tokens, i)
            break
        end
        i, node = parse_norg(m, tokens, i, [AST.ParagraphSegment, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        elseif !isnothing(node)
            push!(children, node)
        end
    end
    i, AST.Node(children, AST.ParagraphSegment())
end

function parse_norg(::Type{T}, tokens, i,
                    parents) where {T <: AST.AttachedModifier}
    children = AST.Node[]
    opening_token = tokens[i]
    i = nextind(tokens, i)
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [T, parents...], tokens, i)
        @debug "Attached modifier loop" token i m
        if isnothing(m)
            break
        end
        i, node = parse_norg(m, tokens, i, [T, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        elseif !isnothing(node)
            push!(children, node)
        end
    end
    if i > lastindex(tokens) || value(tokens[i]) != value(opening_token) # we've been tricked in thincking we were in a modifier.
        pushfirst!(children, AST.Node(AST.Word(value(opening_token))))
        i, children
    elseif isempty(children)
        i = nextind(tokens, i)
        i, nothing
    else
        i = nextind(tokens, i)
        i, AST.Node(children, T())
    end
end

function parse_norg(::Type{AST.Escape}, tokens, i, parents)
    begin
        next_i = nextind(tokens, i)
        if get(tokens, next_i, nothing) isa Union{Token{Tokens.Word}, Nothing}
            next_i, nothing
        else
            nextind(tokens, next_i), AST.Node(AST.Escape(value(tokens[next_i])))
        end
    end
end

function parse_norg(::Type{AST.Link}, tokens, i, parents)
    i = nextind(tokens, i)
    i, location_node = parse_norg(AST.LinkLocation, tokens, i,
                                  [AST.Link, parents...])
    @debug "parsing link" i location_node tokens[i]
    if location_node isa Vector{AST.Node}
        i, location_node
    elseif i <= lastindex(tokens) &&
           tokens[i] isa Token{Tokens.LeftSquareBracket}
        opening_token = tokens[i]
        i = nextind(tokens, i)
        i, description_node = parse_norg(AST.LinkDescription, tokens, i,
                                         [AST.Link, parents...])
        @debug "description returned" location_node description_node
        if description_node isa Vector{AST.Node}
            link_node = AST.Node(AST.Node[location_node], AST.Link())
            opening_node = AST.Node(AST.Word(value(opening_token)))
            i, [link_node, opening_node, description_node...]
        else
            i, AST.Node(AST.Node[location_node, description_node], AST.Link())
        end
    else
        i, AST.Node(AST.Node[location_node], AST.Link())
    end
end

function parse_norg(::Type{U}, tokens, i, parents) where {U <: AST.LinkLocation}
    children = AST.Node[]

    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [U, parents...], tokens, i)
        if isnothing(m)
            break
        end
        i, node = parse_norg(m, tokens, i, [U, parents...])
        push!(children, node)
    end
    if i > lastindex(tokens) || tokens[i] isa Tokens.LineEnding
        i, children
    else
        i = nextind(tokens, i)
        @debug "leaving LinkLocation" i tokens[i]
        i, AST.Node(children, AST.URLLocation())
    end
end

function parse_norg(::Type{AST.LinkDescription}, tokens, i, parents)
    @debug "parsing link description"
    children = AST.Node[]
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.LinkDescription, parents...], tokens, i)
        @debug "link description loop" token i m
        if isnothing(m)
            break
        end
        i, node = parse_norg(m, tokens, i, [AST.LinkDescription, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        else
            push!(children, node)
        end
    end
    if i > lastindex(tokens) || tokens[i] isa Tokens.LineEnding
        i, children
    else
        i = nextind(tokens, i)
        i, AST.Node(children, AST.LinkDescription())
    end
end

function parse_norg(::Type{AST.Word}, tokens, i, parents)
    nextind(tokens, i), AST.Node(AST.Word(value(tokens[i])))
end

export parse_norg
end
