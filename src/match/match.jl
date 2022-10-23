"""
This module exports `match_norg` which matches token sequences to [`NodeData`](@ref) types.
"""
module Match
using ..Kinds
using ..Strategies
using ..AST
using ..Tokens

struct MatchResult 
    kind::Kind
    found::Bool
    closing::Bool
    continued::Bool
    consume::Bool
end
MatchNotFound() = MatchResult(K"None", false, false, false, false)
MatchClosing(k::Kind, consume=true) = MatchResult(k, true, true, false, consume)
MatchFound(k::Kind, consume=true) = MatchResult(k, true, false, false, consume)
MatchContinue() = MatchResult(K"None", true, false, true, true)

isfound(m::MatchResult) = m.found
isclosing(m::MatchResult) = m.closing
iscontinue(m::MatchResult) = m.continued
isnotfound(m::MatchResult) = !m.found
consume(m::MatchResult) = m.consume
matched(m::MatchResult)= m.kind

function Base.show(io::IO, m::MatchResult)
    if isclosing(m)
        print(io, "MatchClosing(")
    elseif iscontinue(m)
        print(io, "MatchContinue(")
    elseif isnotfound(m)
        print(io, "MatchNotFound(")
    else
        print(io, "MatchFound(")
    end
    print(io, "kind=$(matched(m)), consume=$(consume(m)))")
end

"""
match_norg([strategy], parents, tokens, i)

Find the appropriate [`Kind`](@ref) for a token when parser is inside
a `parents` block parsing the `tokens` list at index `i`.

Return a [`Norg.Match.MatchResult`](@ref).

When `strategy` is not specified, must return a [`Norg.Match.MatchFound`](@ref)
or a [`Norg.Match.MatchClosing`](@ref).
"""
function match_norg end

include("attached_modifiers.jl")
include("detached_modifiers.jl")
include("tags.jl")
include("links.jl")

function force_word_context(parents, tokens, i)
    k = kind(first(parents))
    if k == K"InlineCode"
        kind(tokens[i]) ∉ [K"`", K"\\"]
    elseif k == K"Verbatim"
        kind(tokens[i]) != K"@"
    elseif k == K"Escape"
        true
    else
        false
    end
end

function match_norg(parents, tokens, i)
    token = tokens[i]
    m = if force_word_context(parents, tokens, i)
        match_norg(Word(), parents, tokens, i)
    elseif kind(token) == K"Whitespace"
        match_norg(Whitespace(), parents, tokens, i)
    elseif kind(token) == K"LineEnding"
        match_norg(LineEnding(), parents, tokens, i)
    elseif kind(token) == K"*"
        match_norg(Star(), parents, tokens, i)
    elseif kind(token) == K"/" 
        match_norg(Slash(), parents, tokens, i)
    elseif kind(token) == K"_"
        match_norg(Underscore(), parents, tokens, i)
    elseif kind(token) == K"-"
        match_norg(Minus(), parents, tokens, i)
    elseif kind(token) == K"!"
        match_norg(ExclamationMark(), parents, tokens, i)
    elseif kind(token) == K"^"
        match_norg(Circumflex(), parents, tokens, i)
    elseif kind(token) == K","
        match_norg(Comma(), parents, tokens, i)
    elseif kind(token) == K"`"
        match_norg(BackApostrophe(), parents, tokens, i)
    elseif kind(token) == K"\\"
        match_norg(BackSlash(), parents, tokens, i)        
    elseif kind(token) == K"="
        match_norg(EqualSign(), parents, tokens, i)        
    elseif kind(token) == K"{"
        match_norg(LeftBrace(), parents, tokens, i)        
    elseif kind(token) == K"}"
        match_norg(RightBrace(), parents, tokens, i)        
    elseif kind(token) == K"]"
        match_norg(RightSquareBracket(), parents, tokens, i)        
    elseif kind(token) == K"["
        match_norg(LeftSquareBracket(), parents, tokens, i)        
    elseif kind(token) == K"~"
        match_norg(Tilde(), parents, tokens, i)        
    elseif kind(token) == K">"
        match_norg(GreaterThanSign(), parents, tokens, i)        
    elseif kind(token) == K"@"
        match_norg(CommercialAtSign(), parents, tokens, i)        
    else
        match_norg(Word(), parents, tokens, i)
    end
    if isnotfound(m)
        m = match_norg(Word(), parents, tokens, i)
    end
    m
end

match_norg(::Word, parents, tokens, i) = MatchFound(K"Word")

function match_norg(::Whitespace, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    next_token = get(tokens, nextind(tokens, i), nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        if kind(next_token) == K"*"
            match_norg(Heading(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"="
            match_norg(StrongDelimiter(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"-"
            m_t = match_norg(WeakDelimiter(), parents, tokens, nextind(tokens, i))
            if isnotfound(m_t)
                match_norg(UnorderedList(), parents, tokens, nextind(tokens, i))
            else
                m_t
            end
        elseif kind(next_token) == K"~"
            match_norg(OrderedList(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K">"
            match_norg(Quote(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"@"
            match_norg(Verbatim(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"_"
            match_norg(HorizontalRule(), parents, tokens, nextind(tokens, i))
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end

function match_norg(::LineEnding, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    if first(parents) == K"NorgDocument" 
        MatchContinue()
    elseif is_line_ending(prev_token)
        nestable_parents = filter(is_nestable, parents[2:end])
        @debug "line ending match" nestable_parents parents
        if length(nestable_parents) > 0
            MatchClosing(first(parents), false)
        else
            MatchClosing(first(parents), true)
        end
    elseif any(is_attached_modifier.(parents))
        match_norg(Word(), parents, tokens, i)
    else
        MatchClosing(K"ParagraphSegment")
    end
end

function match_norg(::Star, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    m = MatchNotFound()
    if isnothing(prev_token) || is_line_ending(prev_token)
        m = match_norg(Heading(), parents, tokens, i)
    end
    if isnotfound(m)
        m = match_norg(Bold(), parents, tokens, i)
    end
    m
end

match_norg(::Slash, parents, tokens, i) = match_norg(Italic(), parents, tokens, i)

function match_norg(::Underscore, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        m = match_norg(HorizontalRule(), parents, tokens, i)
        if isnotfound(m)
            match_norg(Underline(), parents, tokens, i)
        else
            m
        end
    else
        match_norg(Underline(), parents, tokens, i)
    end
end

function match_norg(::Minus, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        possible_node = [
        WeakDelimiter(),
        UnorderedList(),
        Strikethrough(),
        ]
        m = MatchNotFound()
        for node in possible_node
            m = match_norg(node, parents, tokens, i)
            if !isnotfound(m)
                break
            end
        end
        m
    else
        match_norg(Strikethrough(), parents, tokens, i)
    end
end

match_norg(::ExclamationMark, parents, tokens, i) = match_norg(Spoiler(), parents, tokens, i)

match_norg(::Circumflex, parents, tokens, i) = match_norg(Superscript(), parents, tokens, i)

match_norg(::Comma, parents, tokens, i) = match_norg(Subscript(), parents, tokens, i)

match_norg(::BackApostrophe, parents, tokens, i) = match_norg(InlineCode(), parents, tokens, i)

match_norg(::BackSlash, parents, tokens, i) = MatchFound(K"Escape")

function match_norg(::EqualSign, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        match_norg(StrongDelimiter(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::LeftBrace, parents, tokens, i)
    if K"Link" ∈ parents
        match_norg(Word(), parents, tokens, i)
    elseif K"LinkDescription" ∈ parents
        match_norg(Word(), parents, tokens, i)
    else
        MatchFound(K"Link")
    end
end

function match_norg(::RightBrace, parents, tokens, i)
    if K"LinkLocation" ∈ parents
        MatchClosing(K"LinkLocation")
    else
        MatchNotFound()
    end
end

function match_norg(::RightSquareBracket, parents, tokens, i)
    if K"LinkDescription" ∈ parents
        MatchClosing(K"LinkDescription")
    else
        MatchNotFound()
    end
end

function match_norg(::LeftSquareBracket, parents, tokens, i)
    if K"LinkDescription" ∈ parents || K"LinkLocation" ∈ parents
        return match_norg(Word(), parents, tokens, i)
    elseif K"Link" ∉ parents
        return match_norg(Anchor(), parents, tokens, i)
    end
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if kind(last_token) == K"]"
        MatchFound(K"LinkDescription")
    else
        MatchClosing(K"Link")
    end
end

function match_norg(::Tilde, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        match_norg(OrderedList(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::GreaterThanSign, parents, tokens, i)
    prev_token = get(tokens, i - 1, nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        match_norg(Quote(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::CommercialAtSign, parents, tokens, i)
    prev_token = get(tokens, prevind(tokens, i), nothing)
    if isnothing(prev_token) || is_line_ending(prev_token)
        match_norg(Verbatim(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

export match_norg, isclosing, iscontinue, matched, isnotfound, consume

end
