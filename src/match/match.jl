"""
This module exports [`Match.match_norg`](@ref) which matches token sequences to [`Kinds.Kind`](@ref) AST nodes.
"""
module Match
using ..Kinds
using ..Strategies
using ..AST
using ..Tokens
import ..consume_until

"""
Holds results of [`Match.match_norg`](@ref). It has a [`Kinds.kind`](@ref), that can
be `found`, can be `closing` (*i.e.* closing an attached modifier), `continued`
(as in "ignore this token and continue parsing"). Whether the parser should 
`consume` or not the current token is given by the `consume` field.
"""
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

Find the appropriate [`Kinds.Kind`](@ref) for a token when parser is inside
a `parents` block parsing the `tokens` list at index `i`.

Return a [`Match.MatchResult`](@ref).
"""
function match_norg end

include("attached_modifiers.jl")
include("detached_modifiers.jl")
include("detached_modifier_extension.jl")
include("tags.jl")
include("links.jl")
include("rangeable_detached_modifier.jl")
include("detached_modifier_suffix.jl")

function force_word_context(parents, tokens, i)
    k = kind(first(parents))
    if K"InlineCode" ∈ parents
        kind(tokens[i]) ∉ [K"`", K"\\"]
    elseif k == K"Verbatim"
        kind(tokens[i]) != K"@"
    elseif k == K"Escape"
        true
    elseif k ∈ KSet"URLLocation LineNumberLocation FileLocation NorgFileLocation"
        kind(tokens[i]) != K"}"
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
    elseif kind(token) == K"<"
        match_norg(LesserThanSign(), parents, tokens, i)        
    elseif kind(token) == K"@"
        match_norg(CommercialAtSign(), parents, tokens, i)        
    elseif kind(token) == K"("
        match_norg(LeftParenthesis(), parents, tokens, i)
    elseif kind(token) == K")"
        match_norg(RightParenthesis(), parents, tokens, i)
    elseif kind(token) == K"+"
        match_norg(Plus(), parents, tokens, i)
    elseif kind(token) == K"#"
        match_norg(NumberSign(), parents, tokens, i)
    elseif kind(token) == K"$"
        match_norg(DollarSign(), parents, tokens, i)
    elseif kind(token) == K":"
        match_norg(Colon(), parents, tokens, i)
    elseif kind(token) == K"EndOfFile"
        MatchClosing(first(parents), false)
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
    prev_token = tokens[prevind(tokens, i)]
    next_token = tokens[nextind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
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
        elseif kind(next_token) == K"+"
            match_norg(WeakCarryoverTag(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"_"
            match_norg(HorizontalRule(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"$"
            match_norg(Definition(), parents, tokens, nextind(tokens, i))
        elseif kind(next_token) == K"^"
            @debug "haha footnote"
            match_norg(Footnote(), parents, tokens, nextind(tokens, i))
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end

function match_norg(::LineEnding, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if first(parents) == K"NorgDocument" 
        MatchContinue()
    elseif is_line_ending(prev_token)
        nestable_parents = filter(is_nestable, parents[2:end])
        attached_parents = filter(is_attached_modifier, parents)
        if length(nestable_parents) > 0
            MatchClosing(first(parents), false)
        elseif length(attached_parents) > 0
            MatchClosing(K"Paragraph", false)
        else
            MatchClosing(first(parents), true)
        end
    elseif K"LinkDescription" ∈ parents
        next_i = nextind(tokens, i)
        next_token = tokens[next_i]
        if kind(next_token) == K"]"
            MatchClosing(first(parents), false)
        elseif first(parents) == K"LinkDescription"
            MatchContinue()
        else
            MatchClosing(K"ParagraphSegment")
        end
    elseif K"LinkLocation" ∈ first(parents, 2)
        next_i = nextind(tokens, i)
        next_token = tokens[next_i]
        if kind(next_token) == K"}"
            MatchClosing(first(parents), false)
        else
            MatchContinue()
        end
    else
        MatchClosing(K"ParagraphSegment")
    end
end

function match_norg(::Star, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    m = MatchNotFound()
    if is_sof(prev_token) || is_line_ending(prev_token)
        m = match_norg(Heading(), parents, tokens, i)
    end
    if isnotfound(m)
        m = match_norg(Bold(), parents, tokens, i)
    end
    m
end

match_norg(::Slash, parents, tokens, i) = match_norg(Italic(), parents, tokens, i)

function match_norg(::Underscore, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
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
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
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

function match_norg(::Circumflex, parents, tokens, i)
    @debug "bonjour c'est circumflex" tokens[i]
    prev_token = tokens[prevind(tokens, i)]
    m = if is_line_ending(prev_token) || is_sof(prev_token)
        match_norg(Footnote(), parents, tokens, i)    
    else
        MatchNotFound()
    end
    if isnotfound(m)
        match_norg(Superscript(), parents, tokens, i)
    else
        m
    end
end

match_norg(::Comma, parents, tokens, i) = match_norg(Subscript(), parents, tokens, i)

match_norg(::BackApostrophe, parents, tokens, i) = match_norg(InlineCode(), parents, tokens, i)

match_norg(::BackSlash, parents, tokens, i) = MatchFound(K"Escape")

function match_norg(::Colon, parents, tokens, i)
    m = match_norg(DetachedModifierSuffix(), parents, tokens, i)
    if isnotfound(m)
        next_i = nextind(tokens, i)
        next_token = tokens[next_i]
        prev_i = prevind(tokens, i)
        prev_token = tokens[prev_i]
        @debug "hey there" kind(prev_token)∈ATTACHED_DELIMITERS prev_token
        if kind(next_token) ∈ ATTACHED_DELIMITERS 
            m = match_norg(parents, tokens, next_i)
            if isfound(m) && AST.is_attached_modifier(kind(matched(m)))
                return MatchContinue()
            end
        end
        MatchNotFound()    
    else
        m
    end
end

function match_norg(::EqualSign, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
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
    elseif !is_whitespace(tokens[nextind(tokens, i)])
        MatchFound(K"Link")
    else
        MatchNotFound()
    end
end

function match_norg(::RightBrace, parents, tokens, i)
    if K"LinkLocation" ∈ parents
        MatchClosing(first(parents))
    else
        MatchNotFound()
    end
end

function match_norg(::RightSquareBracket, parents, tokens, i)
    if K"LinkDescription" ∈ parents
        MatchClosing(K"LinkDescription", first(parents) == K"LinkDescription")
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
    last_token = tokens[prev_i]
    next_i = nextind(tokens,i)
    next_token = tokens[next_i]
    if kind(last_token) == K"}" && kind(next_token) != K"LineEnding"
        MatchFound(K"LinkDescription")
    else
        MatchClosing(K"Link")
    end
end

function match_norg(::Tilde, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
        match_norg(OrderedList(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::GreaterThanSign, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
        match_norg(Quote(), parents, tokens, i)
    elseif K"InlineLinkTarget" ∈ parents
        MatchClosing(K"InlineLinkTarget", first(parents) == K"InlineLinkTarget")
    else
        MatchNotFound()
    end
end

match_norg(::LesserThanSign, parents, tokens, i) = match_norg(InlineLinkTarget(), parents, tokens, i)

tag_to_strategy(::CommercialAtSign) = Verbatim()
tag_to_strategy(::Plus) = WeakCarryoverTag()
tag_to_strategy(::NumberSign) = StrongCarryoverTag()

function match_norg(t::Union{CommercialAtSign, Plus, NumberSign}, parents, tokens, i)
    prev_token = tokens[prevind(tokens, i)]
    if is_sof(prev_token) || is_line_ending(prev_token)
        match_norg(tag_to_strategy(t), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::DollarSign, parents, tokens, i)
    @debug "bonjour c'est dollarsign"
    prev_token = tokens[prevind(tokens, i)]
    if is_line_ending(prev_token) || is_sof(prev_token)
        match_norg(Definition(), parents, tokens, i)    
    else
        MatchNotFound()
    end
end

function match_norg(::LeftParenthesis, parents, tokens, i)
    if is_detached_modifier(first(parents)) || (length(parents) > 1 && is_detached_modifier(parents[2]))
        match_norg(DetachedModifierExtension(), parents, tokens, i)
    else
        MatchNotFound()
    end
end

function match_norg(::RightParenthesis, parents, tokens, i)
    if any(is_detached_modifier_extension.(parents))
        _, grandparents... = parents
        MatchClosing(first(parents), !any(is_detached_modifier_extension.(grandparents)))
    else
        MatchNotFound()
    end
end

export match_norg, isclosing, iscontinue, matched, isnotfound, consume, isfound

end
