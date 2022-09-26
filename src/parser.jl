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
    consume_until(T, tokens, i)

Consume tokens until a token of type T is encountered, or final token is reached.
"""
function consume_until(::Type{T}, tokens, i) where T<:Tokens.TokenType
    token = get(tokens, i, nothing)
    while i<lastindex(tokens) && !(token isa Token{T})
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
        i, paragraph = parse_norg(AST.FirstClassNode, tokens, i, [AST.NorgDocument])
        if !isnothing(paragraph)
            push!(paragraphs, paragraph)
        end
    end
    i, AST.Node(paragraphs, AST.NorgDocument())
end

function parse_norg(::Type{AST.FirstClassNode}, tokens, i, parents)
    token = get(tokens, i, nothing)
    m = match_norg(token, parents, tokens, i)
    if isnothing(m)
        i = nextind(tokens, i)
        i, nothing
    elseif m <: AST.Heading
        parse_norg(m, tokens, i, parents)
    elseif m <: AST.HorizontalRule 
        i = consume_until(Tokens.LineEnding, tokens, i)
        i, AST.Node(AST.Node[], m())
    elseif m <: AST.DelimitingModifier 
        i = consume_until(Tokens.LineEnding, tokens, i)
        i, nothing
    else
        parse_norg(AST.Paragraph, tokens, i, parents)
    end
end

function parse_norg(::Type{AST.Paragraph}, tokens, i, parents)
    segments = AST.Node[]
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.Paragraph, parents...], tokens, i)
        if m <: AST.DelimitingModifier
            break
        elseif m <: AST.Heading
            break
        else
            i, segment = parse_norg(AST.ParagraphSegment, tokens, i,
                                [AST.Paragraph, parents...])
            push!(segments, segment)
        end
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
        if isnothing(m)
            i = nextind(tokens, i)
            break
        elseif m <: AST.DelimitingModifier 
            break
        elseif m <: AST.Heading
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
    if location_node isa Vector{AST.Node}
        i, location_node
    elseif i <= lastindex(tokens) &&
           tokens[i] isa Token{Tokens.LeftSquareBracket}
        opening_token = tokens[i]
        i = nextind(tokens, i)
        i, description_node = parse_norg(AST.LinkDescription, tokens, i,
                                         [AST.Link, parents...])
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
        i, AST.Node(children, AST.URLLocation())
    end
end

function parse_norg(::Type{AST.LinkDescription}, tokens, i, parents)
    children = AST.Node[]
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg(token, [AST.LinkDescription, parents...], tokens, i)
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

function parse_norg(t::Type{AST.Heading{T}}, tokens, i, parents) where {T}
    token = get(tokens, i, nothing)
    if token isa Token{Tokens.Whitespace} # consume leading whitespace
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    heading_level = 0
    # Consume stars to determine heading level
    while i < lastindex(tokens) && token isa Token{Tokens.Star}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        heading_level += 1
    end
    if token isa Token{Tokens.Whitespace}
        i, title_segment = parse_norg(AST.ParagraphSegment, tokens, nextind(tokens, i), [AST.Heading, parents...])
        children = AST.Node[]
        while i < lastindex(tokens)
            token = get(tokens, i, nothing)
            m = match_norg(token, [t, parents...], tokens, i)
            if isnothing(m)
                break
            elseif m <: AST.Heading
                i, child = parse_norg(m, tokens, i, [t, parents...])
            elseif m <: AST.WeakDelimitingModifier 
                i = consume_until(Tokens.LineEnding, tokens, i)
                break
            elseif m <: AST.StrongDelimitingModifier
                break
            else
                i, child = parse_norg(AST.Paragraph, tokens, i, [t, parents...])
            end
            push!(children, child)
        end
        i, AST.Node(children, t(title_segment))
    else # if the stars are not followed by a whitespace, toss them aside and fall back on a paragraph.
            parse_norg(AST.Paragraph, tokens, i, parents)
    end
end

function parse_norg(::Type{AST.Word}, tokens, i, parents)
    nextind(tokens, i), AST.Node(AST.Word(value(tokens[i])))
end

export parse_norg
end
