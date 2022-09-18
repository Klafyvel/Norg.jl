"""
This module exports `match_norg` which matches token sequences to [`AST.NodeData`](@ref) types.
"""
module Match
using ..AST
using ..Tokens

tokentype(::Type{AST.ParagraphSegment}) = Tokens.LineEnding
tokentype(::Type{AST.Bold}) = Tokens.Star
tokentype(::Type{AST.Italic}) = Tokens.Slash
tokentype(::Type{AST.Underline}) = Tokens.Underscore
tokentype(::Type{AST.Strikethrough}) = Tokens.Minus
tokentype(::Type{AST.Spoiler}) = Tokens.ExclamationMark
tokentype(::Type{AST.Superscript}) = Tokens.Circumflex
tokentype(::Type{AST.Subscript}) = Tokens.Comma
tokentype(::Type{AST.InlineCode}) = Tokens.BackApostrophe

const AllowedBeforeAttachedModifierOpening = Union{Token{Tokens.Whitespace},
                                                   Token{
                                                         <:Tokens.AbstractPunctuation
                                                         },
                                                   Nothing}
const ForbiddenAfterAttachedModifierOpening = Union{Token{Tokens.Whitespace},
                                                    Nothing}
const AllowedAfterAttachedModifier = Union{Token{Tokens.Whitespace},
                                           Token{<:Tokens.AbstractPunctuation},
                                           Nothing}

# TODO: rewrite the matching to take all the parents in account.
function match_attached_modifier(::Type{AST.ParagraphSegment}, tokens, i,
                                 ast_node, parents)
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
        ast_node
    else
        AST.Word
    end
end

function match_attached_modifier(T::Type{AST.LinkLocation}, tokens, i, ast_node,
                                 parents)
    AST.Word
end

function match_attached_modifier(T::Type{<:AST.MatchedInline}, tokens, i,
                                 ast_node, parents)
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
        ast_node
    elseif !(last_token isa Token{Tokens.Whitespace}) &&
           next_token isa AllowedAfterAttachedModifier
        if any(t -> tokens[i] isa Token{tokentype(t)}, parents)
            nothing
        else
            AST.Word
        end
    else
        AST.Word
    end
end

function match_attached_modifier(::Type{AST.InlineCode}, tokens, i, ast_node,
                                 parents)
    token = tokens[i]
    if !(token isa Token{Tokens.BackApostrophe})
        return AST.Word
    end
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
        ast_node
    elseif !(last_token isa Token{Tokens.Whitespace}) &&
           next_token isa AllowedAfterAttachedModifier
        nothing
    else
        AST.Word
    end
end

"""
match_norg(token, parents, tokens, i)

Find the appropriate [`AST.NodeData`](@reg) for a `token` when parser is inside
a `parents` block parsing the `tokens` list at index `i`
"""
function match_norg end

match_norg(::Token, parents, tokens, i) = AST.Word
match_norg(::Token{Tokens.LineEnding}, parents, tokens, i) = nothing
function match_norg(::Token{Tokens.Star}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Bold, parents)
end
function match_norg(::Token{Tokens.Slash}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Italic, parents)
end
function match_norg(::Token{Tokens.Underscore}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Underline, parents)
end
function match_norg(::Token{Tokens.Minus}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Strikethrough, parents)
end
function match_norg(::Token{Tokens.ExclamationMark}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Spoiler, parents)
end
function match_norg(::Token{Tokens.Circumflex}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Superscript, parents)
end
function match_norg(::Token{Tokens.Comma}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Subscript, parents)
end
function match_norg(::Token{Tokens.BackApostrophe}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.InlineCode, parents)
end
match_norg(::Token{Tokens.BackSlash}, parents, tokens, i) = AST.Escape

function match_norg(::Token{Tokens.LeftBrace}, parents, tokens, i)
    if AST.Link ∈ parents
        AST.Word
    elseif AST.LinkDescription ∈ parents
        AST.Word
    else
        AST.Link
    end
end

function match_norg(::Token{Tokens.RightBrace}, parents, tokens, i)
    if AST.LinkLocation ∈ parents
        nothing
    else
        AST.Word
    end
end
function match_norg(::Token{Tokens.RightSquareBracket}, parents, tokens, i)
    if AST.LinkDescription ∈ parents
        nothing
    else
        AST.Word
    end
end
function match_norg(::Token{Tokens.LeftSquareBracket}, parents, tokens, i)
    if AST.LinkDescription ∈ parents || AST.LinkLocation ∈ parents
        return AST.Word
    end
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa Token{Tokens.RightSquareBracket}
        AST.LinkDescription
    else
        nothing
    end
end

export match_norg
end
