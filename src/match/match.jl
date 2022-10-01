"""
This module exports `match_norg` which matches token sequences to [`AST.NodeData`](@ref) types.
"""
module Match
using ..AST
using ..Tokens

abstract type MatchResult end
struct MatchNotFound <: MatchResult end
struct MatchClosing{T<:AST.NodeData} <: MatchResult end
struct MatchFound{T<:AST.NodeData} <: MatchResult end

isclosing(m) = m isa MatchClosing
matched(::MatchClosing{T}) where {T} = T
matched(::MatchFound{T}) where {T} = T

"""
match_norg([[firstparenttype], astnodetype], token, parents, tokens, i)

Find the appropriate [`AST.NodeData`](@ref) for a `token` when parser is inside
a `parents` block parsing the `tokens` list at index `i`.

If `astnodetype` is set, try to match an AST node of the given type. Return 
nothing if it fails. If firstparenttype is given, the matching is altered with
the correspondig context. This allows disabling some features in *e.g.* 
verbatim context.

Return a [`Norg.Match.MatchResult`](@ref).

When `astnodetype` is not specified, must return a [`Norg.Match.MatchFound`](@ref)
or a [`Norg.Match.MatchClosing`](@ref).
"""
function match_norg end

include("attached_modifiers.jl")
include("detached_modifiers.jl")

# Default to matching a word.
match_norg(::Token, parents, tokens, i) = MatchFound{AST.Word}()

function match_norg(::Token{Tokens.Whitespace}, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    next_token = get(tokens, nextind(tokens, i), nothing)
    if prev_token isa Union{Nothing, Token{Tokens.LineEnding}}
        m = if next_token isa Token{Tokens.Star}
            match_norg(AST.Heading, next_token, parents, tokens, nextind(tokens, i))
        elseif next_token isa Token{Tokens.EqualSign}
            match_norg(AST.DelimitingModifier, next_token, parents, tokens, nextind(tokens, i))
        elseif next_token isa Token{Tokens.Minus}
            match_norg(AST.DelimitingModifier, next_token, parents, tokens, nextind(tokens, i))
        else
            MatchFound{AST.Word}()
        end
        if m isa MatchNotFound
            MatchFound{AST.Word}()
        else
            m
        end
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Token{Tokens.LineEnding}, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    if prev_token isa Token{Tokens.LineEnding}
        MatchClosing{AST.Paragraph}()
    elseif any(isa.(parents, AST.AttachedModifier))
        MatchFound{AST.Word}()
    else
        MatchClosing{AST.ParagraphSegment}()
    end
end

function match_norg(t::Token{Tokens.Star}, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    m = MatchNotFound()
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_norg(AST.Heading, t, parents, tokens, i)
    end
    if m isa MatchNotFound
        m = match_norg(parents[1], AST.Bold, t, parents, tokens, i)
    end
    m
end

function match_norg(t::Token{Tokens.Slash}, parents, tokens, i)
    match_norg(parents[1], AST.Italic, t, parents, tokens, i)
end

function match_norg(t::Token{Tokens.Underscore}, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_norg(AST.DelimitingModifier, t, parents, tokens, i)
        if m isa MatchNotFound
            match_norg(parents[1], AST.Underline, t, parents, tokens, i)
        else
            m
        end
    else
        match_norg(parents[1], AST.Underline, t, parents, tokens, i)
    end
end

function match_norg(t::Token{Tokens.Minus}, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_norg(AST.DelimitingModifier, t, parents, tokens, i)
        if m isa MatchNotFound
            match_norg(parents[1], AST.Strikethrough, t, parents, tokens, i)
        else
            m
        end
    else
        match_norg(parents[1], AST.Strikethrough, t, parents, tokens, i)
    end
end

function match_norg(t::Token{Tokens.ExclamationMark}, parents, tokens, i)
    match_norg(parents[1], AST.Spoiler, t, parents, tokens, i)
end

function match_norg(t::Token{Tokens.Circumflex}, parents, tokens, i)
    match_norg(parents[1], AST.Superscript, t, parents, tokens, i)
end

function match_norg(t::Token{Tokens.Comma}, parents, tokens, i)
    match_norg(parents[1], AST.Subscript, t, parents, tokens, i)
end

function match_norg(t::Token{Tokens.BackApostrophe}, parents, tokens, i)
    match_norg(parents[1], AST.InlineCode, t, parents, tokens, i)
end

match_norg(::Token{Tokens.BackSlash}, parents, tokens, i) = MatchFound{AST.Escape}()

function match_norg(t::Token{Tokens.EqualSign}, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_norg(AST.DelimitingModifier, t, parents, tokens, i)
        if m isa MatchNotFound
            MatchFound{AST.Word}()
        else
            m
        end
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Token{Tokens.LeftBrace}, parents, tokens, i)
    if AST.Link ∈ parents
        MatchFound{AST.Word}()
    elseif AST.LinkDescription ∈ parents
        MatchFound{AST.Word}()
    else
        MatchFound{AST.Link}()
    end
end

function match_norg(::Token{Tokens.RightBrace}, parents, tokens, i)
    if AST.LinkLocation ∈ parents
        MatchClosing{AST.LinkLocation}()
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Token{Tokens.RightSquareBracket}, parents, tokens, i)
    if AST.LinkDescription ∈ parents
        MatchClosing{AST.LinkDescription}()
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Token{Tokens.LeftSquareBracket}, parents, tokens, i)
    if AST.LinkDescription ∈ parents || AST.LinkLocation ∈ parents
        return MatchFound{AST.Word}()
    end
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa Token{Tokens.RightSquareBracket}
        MatchFound{AST.LinkDescription}()
    else
        MatchClosing{AST.Link}()
    end
end

export match_norg, isclosing, matched
end
