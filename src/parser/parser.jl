"""
This module defines the [`Parser.parse_norg`](@ref) function, which builds
an AST from a token list.

The role of [`Parser.parse_norg`](@ref) is to *consume* tokens. To do so, it
relies on [`Match.match_norg`](@ref) to take decisions on how to consume
tokens.
"""
module Parser

using AbstractTrees

using ..Kinds
using ..Strategies
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
    consume_until(k, tokens, i)

Consume tokens until a token of kind `k` is encountered, or final token is reached.
"""
function consume_until(k::Kind, tokens, i)
    token = tokens[i]
    while !is_eof(token) && kind(token) != k
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) == k
        i = nextind(tokens, i)
    end
    i
end

"""
    parse_norg(strategy, tokens, i)

Try to parse the `tokens` sequence starting at index `i` using a given `strategy`.
"""
function parse_norg end

"""
    parse_norg(tokens)

Try to parse the `tokens` sequence as an [`AST.NorgDocument`](@ref) starting
from the begining of the sequence.
"""
function parse_norg(tokens)
    i = nextind(tokens, firstindex(tokens))
    paragraphs = AST.Node[]
    while !is_eof(tokens[i])
        m = match_norg([K"NorgDocument"], tokens, i)
        if isclosing(m)
            error("Closing token when parsing NorgDocument at token $(tokens[i]). This is a bug, please report it along with the text you are trying to parse.")
            return AST.NorgDocument(AST.Node[], tokens)
        elseif iscontinue(m)
            i = nextind(tokens, i)
            continue
        end
        to_parse = matched(m)
        paragraph = if is_delimiting_modifier(to_parse)
            start = i
            stop = consume_until(K"LineEnding", tokens, i)
            AST.Node(to_parse, AST.Node[], start, stop)
        elseif is_quote(to_parse)
            parse_norg(Quote(), [K"NorgDocument"], tokens, i) 
        elseif is_unordered_list(to_parse)
            parse_norg(UnorderedList(), [K"NorgDocument"], tokens, i) 
        elseif is_ordered_list(to_parse)
            parse_norg(OrderedList(), [K"NorgDocument"], tokens, i) 
        elseif kind(to_parse) == K"Verbatim"
            parse_norg(Verbatim(), [K"NorgDocument"], tokens, i)
        elseif is_heading(to_parse)
            parse_norg(Heading(), [K"NorgDocument"], tokens, i)
        else
            parse_norg(Paragraph(), [K"NorgDocument"], tokens, i)
        end
        i = AST.stop(paragraph)
        if !is_eof(tokens[i])
            i = nextind(tokens, i)
        end
        if kind(paragraph) != K"None"
            push!(paragraphs, paragraph)
        end
    end
    AST.NorgDocument(paragraphs, tokens)
end

function parse_norg(::Paragraph, parents::Vector{Kind}, tokens, i)
    segments = AST.Node[]
    m = Match.MatchClosing(K"Paragraph")
    start = i
    while !is_eof(tokens[i])
        m = match_norg([K"Paragraph", parents...], tokens, i)
        if isclosing(m)
            break
        elseif iscontinue(m)
            i = nextind(tokens, i)
            continue
        end
        to_parse = matched(m)
        if is_delimiting_modifier(to_parse)
            break
        elseif is_heading(to_parse)
            break
        else
            segment = parse_norg(ParagraphSegment(), [K"Paragraph", parents...], tokens, i)
            i = nextind(tokens, AST.stop(segment))
            if kind(segment) == K"None"
                append!(segments, children(segment))
            else
                push!(segments, segment)
            end
        end
    end
    if is_eof(tokens[i])
        i = prevind(tokens, i)
    elseif isclosing(m) && matched(m) == K"Paragraph" && !consume(m)
        i = prevind(tokens, i)
    elseif isclosing(m) && matched(m) != K"Paragraph"
        i = prevind(tokens, i)
    end
    AST.Node(K"Paragraph", segments, start, i)
end

"""
Main dispatch utility.
"""
function parse_norg_dispatch(to_parse, parents::Vector{Kind}, tokens, i)
    if to_parse == K"Escape"
        parse_norg(Escape(), parents, tokens, i)            
    elseif to_parse == K"Bold"
        parse_norg(Bold(), parents, tokens, i)            
    elseif to_parse == K"Italic"
        parse_norg(Italic(), parents, tokens, i)            
    elseif to_parse == K"Underline"
        parse_norg(Underline(), parents, tokens, i)            
    elseif to_parse == K"Strikethrough"
        parse_norg(Strikethrough(), parents, tokens, i)            
    elseif to_parse == K"Spoiler"
        parse_norg(Spoiler(), parents, tokens, i)            
    elseif to_parse == K"Superscript"
        parse_norg(Superscript(), parents, tokens, i)            
    elseif to_parse == K"Subscript"
        parse_norg(Subscript(), parents, tokens, i)            
    elseif to_parse == K"InlineCode"
        parse_norg(InlineCode(), parents, tokens, i)            
    elseif to_parse == K"Link"
        parse_norg(Link(), parents, tokens, i)            
    elseif to_parse == K"Anchor"
        parse_norg(Anchor(), parents, tokens, i)
    elseif to_parse == K"InlineLinkTarget"
        parse_norg(InlineLinkTarget(), parents, tokens, i)
    elseif to_parse == K"Word"
        parse_norg(Word(), parents, tokens, i)
    else
        error("parse_norg_dispatch got an unhandled node kind $to_parse for token $(tokens[i])")
    end
end

function parse_norg(::ParagraphSegment, parents::Vector{Kind}, tokens, i)
    start = i
    children = AST.Node[]
    m = Match.MatchClosing(K"ParagraphSegment")
    parents = [K"ParagraphSegment", parents...]
    siblings = []
    while !is_eof(tokens[i])
        m = match_norg(parents, tokens, i)
        if isclosing(m)
            break
        end
        to_parse = matched(m)
        if is_delimiting_modifier(to_parse)
            break
        elseif is_heading(to_parse)
            break
        end
        node = parse_norg_dispatch(to_parse, parents, tokens, i)
        i = nextind(tokens, AST.stop(node))
        if kind(node) == K"None"
            for c in node.children
                if kind(c) == K"ParagraphSegment"
                    push!(siblings, c)
                else
                    push!(children, c)
                end
            end
        else
            push!(children, node)
        end
    end
    if !consume(m) || is_eof(tokens[i])
        i = prevind(tokens, i)
    end
    ps = AST.Node(K"ParagraphSegment", children, start, i)
    if isempty(siblings)
        ps
    elseif AST.start(first(siblings)) == start
        AST.Node(K"None", siblings, start, i)
    else
        ps = AST.Node(K"ParagraphSegment", vcat(children, first(siblings).children), start, i)
        if length(siblings) > 1
            AST.Node(K"None", [ps, siblings[2:end]...], start, i)
        else
            ps
        end
    end
end

function parse_norg(::Escape, parents::Vector{Kind}, tokens, i)
    next_i = nextind(tokens, i)
    w = parse_norg(Word(), parents, tokens, next_i)
    AST.Node(K"Escape", AST.Node[w], i, next_i)
end

function parse_norg(::Word, parents::Vector{Kind}, tokens, i)
    AST.Node(K"WordNode", AST.Node[], i, i)
end

include("attachedmodifier.jl")
include("link.jl")
include("structuralmodifier.jl")
include("verbatim.jl")
include("nestablemodifier.jl")

export parse_norg
end
