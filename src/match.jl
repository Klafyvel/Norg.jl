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

function match_attached_modifier(::Type{AST.NorgDocument}, tokens, i, ast_node, parents)
    match_attached_modifier(AST.ParagraphSegment, tokens, i, ast_node, parents)
end

function match_attached_modifier(::Type{AST.Paragraph}, tokens, i, ast_node, parents)
    match_attached_modifier(AST.ParagraphSegment, tokens, i, ast_node, parents)
end

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

function match_attached_modifier(::Type{AST.LinkLocation}, tokens, i, ast_node,
        parents)
    AST.Word
end

function match_attached_modifier(::Type{<:AST.MatchedInline}, tokens, i,
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
        if any(t -> tokens[i] isa Token{tokentype(t)}, filter(x->x<:AST.MatchedInline, parents))
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

function match_heading(parents, tokens, i)
    new_i = i
    heading_level = 0
    while new_i < lastindex(tokens) && get(tokens, new_i, nothing) isa Token{Tokens.Star}
        new_i = nextind(tokens, new_i)
        heading_level += 1
    end
    next_token = get(tokens, new_i, nothing)
    if next_token isa Token{Tokens.Whitespace}
        previous_heading_level = AST.headinglevel.(filter(x->x <: AST.Heading, parents))
        if any(previous_heading_level .> heading_level)
            nothing
        else
            AST.Heading{heading_level}
        end
    else
        match_attached_modifier(parents[1], tokens, i, AST.Bold, parents)
    end
end

delimitingmodifier(::Type{Tokens.EqualSign}) = AST.StrongDelimitingModifier
delimitingmodifier(::Type{Tokens.Minus}) = AST.WeakDelimitingModifier
delimitingmodifier(::Type{Tokens.Underscore}) = AST.HorizontalRule

function match_delimiting_modifier(::Token{T}, tokens, i) where {T}
    next_i = nextind(tokens, i)
    next_next_i = nextind(tokens, next_i)
    next_token = get(tokens, next_i, nothing)
    next_next_token = get(tokens, next_next_i, nothing)
    if next_token isa Token{T} && next_next_token isa Token{T}
        new_i = nextind(tokens, next_next_i)
        token = get(tokens, new_i, nothing)
        is_delimiting = true
        while new_i < lastindex(tokens) && !(token isa Token{Tokens.LineEnding})
            if !(token isa Token{T})
                is_delimiting = false
                break
            end
            new_i = nextind(tokens, next_next_i)
            token = get(tokens, new_i, nothing)
        end
        if is_delimiting 
            delimitingmodifier(T)
        else
            nothing
        end
    else
        nothing
    end
end

"""
match_norg(token, parents, tokens, i)

Find the appropriate [`AST.NodeData`](@reg) for a `token` when parser is inside
a `parents` block parsing the `tokens` list at index `i`
"""
function match_norg end

match_norg(::Token, parents, tokens, i) = AST.Word
function match_norg(::Token{Tokens.Whitespace}, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    next_token = get(tokens, nextind(tokens, i), nothing)
    if prev_token isa Union{Nothing, Token{Tokens.LineEnding}} 
        m = if next_token isa Token{Tokens.Star}
            match_heading(parents, tokens, nextind(tokens, i))
        elseif next_token isa Token{Tokens.EqualSign}
            match_delimiting_modifier(next_token, tokens, nextind(tokens, i))
        elseif next_token isa Token{Tokens.Minus}
            match_delimiting_modifier(next_token, tokens, nextind(tokens, i))
        else
            AST.Word
        end
        if isnothing(m)
            AST.Word
        else
            m
        end
    else
        AST.Word
    end
end
# TODO: LineEndings are allowed inside Attached modifiers !!!
match_norg(::Token{Tokens.LineEnding}, parents, tokens, i) = nothing
function match_norg(::Token{Tokens.Star}, parents, tokens, i)
    prev_token = get(tokens, i-1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        match_heading(parents, tokens, i)
    else
        match_attached_modifier(parents[1], tokens, i, AST.Bold, parents)
    end
end
function match_norg(::Token{Tokens.Slash}, parents, tokens, i)
    match_attached_modifier(parents[1], tokens, i, AST.Italic, parents)
end
function match_norg(t::Token{Tokens.Underscore}, parents, tokens, i)
    prev_token = get(tokens, i-1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_delimiting_modifier(t, tokens, i)
        if isnothing(m)
            match_attached_modifier(parents[1], tokens, i, AST.Underline, parents)
        else
            m
        end
    else
       match_attached_modifier(parents[1], tokens, i, AST.Underline, parents)
    end
end
function match_norg(t::Token{Tokens.Minus}, parents, tokens, i)
    prev_token = get(tokens, i-1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_delimiting_modifier(t, tokens, i)
        if isnothing(m)
            match_attached_modifier(parents[1], tokens, i, AST.Strikethrough, parents)
        else
            m
        end
    else
        match_attached_modifier(parents[1], tokens, i, AST.Strikethrough, parents)
    end
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
function match_norg(t::Token{Tokens.EqualSign}, parents, tokens, i)
    prev_token = get(tokens, i-1, nothing)
    if prev_token isa Union{Token{Tokens.LineEnding}, Nothing}
        m = match_delimiting_modifier(t, tokens, i)
        if isnothing(m)
            AST.Word
        else
            m
        end
    else
        AST.Word
    end
end


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
