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
import ..consume_until
import ..findtargets!

"""
    parse_norg(strategy, tokens, i)

Try to parse the `tokens` sequence starting at index `i` using a given `strategy`.
"""
function parse_norg end

function parse_norg_toplevel_one_step(parents::Vector{Kind}, tokens::Vector{Token}, i)
    m = match_norg(parents, tokens, i)
    to_parse = matched(m)
    if isclosing(m)
        error("Closing token when parsing a top level element at token $(tokens[i]). This is a bug, please report it along with the text you are trying to parse.")
        return AST.Node(K"None", AST.Node[], i, nextind(tokens, i))
    elseif iscontinue(m)
        return AST.Node(K"None", AST.Node[], i, i)
    end
    if is_delimiting_modifier(to_parse)
        start = i
        stop = prevind(tokens, consume_until(K"LineEnding", tokens, i))
        AST.Node(to_parse, AST.Node[], start, stop)
    elseif is_quote(to_parse)
        parse_norg(Quote(), parents, tokens, i) 
    elseif is_unordered_list(to_parse)
        parse_norg(UnorderedList(), parents, tokens, i) 
    elseif is_ordered_list(to_parse)
        parse_norg(OrderedList(), parents, tokens, i) 
    elseif kind(to_parse) == K"Verbatim"
        parse_norg(Verbatim(), parents, tokens, i)
    elseif is_heading(to_parse)
        parse_norg(Heading(), parents, tokens, i)
    elseif to_parse == K"WeakCarryoverTag"
        parse_norg(WeakCarryoverTag(), parents, tokens, i)
    elseif to_parse == K"StrongCarryoverTag"
        parse_norg(StrongCarryoverTag(), parents, tokens, i)
    elseif to_parse == K"ParagraphSegment"
        parse_norg(ParagraphSegment(), parents, tokens, i)
    elseif to_parse == K"NestableItem"
        parse_norg(NestableItem(), parents, tokens, i)
    elseif to_parse == K"Definition"
        parse_norg(Definition(), parents, tokens, i)
    elseif to_parse == K"Footnote"
        parse_norg(Footnote(), parents, tokens, i)
    else
        parse_norg(Paragraph(), parents, tokens, i)
    end
end

"""
    parse_norg(tokens)

Try to parse the `tokens` sequence as an [`AST.NorgDocument`](@ref) starting
from the begining of the sequence.
"""
function parse_norg(tokens::Vector{Token})
    i = nextind(tokens, firstindex(tokens))
    children = AST.Node[]
    while !is_eof(tokens[i])
        child = parse_norg_toplevel_one_step([K"NorgDocument"], tokens, i)
        @debug "toplevel" i child tokens[i]
        i = AST.stop(child)
        if !is_eof(tokens[i])
            i = nextind(tokens, i)
        end
        if kind(child) != K"None"
            push!(children, child)
        end
    end
    root = AST.Node(K"NorgDocument", children, firstindex(tokens), lastindex(tokens))
    ast = AST.NorgDocument(root, tokens)
    findtargets!(ast)
    ast
end

function parse_norg(::Paragraph, parents::Vector{Kind}, tokens::Vector{Token}, i)
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
            target = if to_parse == K"WeakCarryoverTag"
                WeakCarryoverTag()
            else
                ParagraphSegment()
            end
            segment = parse_norg(target, [K"Paragraph", parents...], tokens, i)
            i = nextind(tokens, AST.stop(segment))
            if kind(segment) ∈ KSet"None Paragraph"
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
function parse_norg_dispatch(to_parse::Kind, parents::Vector{Kind}, tokens::Vector{Token}, i)
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
    elseif to_parse == K"NullModifier"
        parse_norg(NullModifier(), parents, tokens, i)
    elseif to_parse == K"InlineMath"
        parse_norg(InlineMath(), parents, tokens, i)
    elseif to_parse == K"Variable"
        parse_norg(Variable(), parents, tokens, i)
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

function parse_norg(::ParagraphSegment, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    children = AST.Node[]
    m = Match.MatchClosing(K"ParagraphSegment")
    parents = [K"ParagraphSegment", parents...]
    siblings = []
    while !is_eof(tokens[i])
        m = match_norg(parents, tokens, i)
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

function parse_norg(::Escape, parents::Vector{Kind}, tokens::Vector{Token}, i)
    next_i = nextind(tokens, i)
    w = parse_norg(Word(), parents, tokens, next_i)
    AST.Node(K"Escape", AST.Node[w], i, next_i)
end

function parse_norg(::Word, parents::Vector{Kind}, tokens::Vector{Token}, i)
    AST.Node(K"WordNode", AST.Node[], i, i)
end

include("attachedmodifier.jl")
include("link.jl")
include("structuralmodifier.jl")
include("tag.jl")
include("nestablemodifier.jl")
include("detachedmodifierextensions.jl")
include("rangeabledetachedmodifier.jl")
include("detachedmodifiersuffix.jl")

export parse_norg
end
