tag(::Verbatim) = K"Verbatim"
tag(::StandardRangedTag) = K"StandardRangedTag"
token_tag(::Verbatim) = K"@"
token_tag(::StandardRangedTag) = K"|"
body(::Verbatim) = K"VerbatimBody"
body(::StandardRangedTag) = K"StandardRangedTagBody"
function match_norg(t::T, parents, tokens, i) where {T<:Tag}
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"Word"
        val = Tokens.value(token)
        if tag(t) ∈ parents && val == "end"
            next_token = tokens[nextind(tokens, i)]
            if kind(next_token) ∈ KSet"LineEnding EndOfFile"
                MatchClosing(tag(t), first(parents) ∈ (tag(t), body(t)))
            else
                MatchNotFound()
            end
        elseif K"Verbatim" ∈ parents
            MatchNotFound()
        elseif kind(first(parents)) ∈ KSet"Slide IndentSegment"
            MatchFound(tag(t))
        elseif !(
            is_nestable(first(parents)) ||
            is_heading(first(parents)) ||
            kind(first(parents)) ∈ KSet"NorgDocument StandardRangedTagBody"
        )
            MatchClosing(first(parents), false)
        else
            MatchFound(tag(t))
        end
    else
        MatchNotFound()
    end
end

function match_norg(::WeakCarryoverTag, parents, tokens, i)
    token = tokens[nextind(tokens, i)]
    if kind(token) == K"Word"
        nextline = consume_until(K"LineEnding", tokens, i)
        m = match_norg(parents, tokens, nextline)
        if isclosing(m)
            m
        else
            MatchFound(K"WeakCarryoverTag")
        end
    else
        MatchNotFound()
    end
end

function match_norg(::StrongCarryoverTag, parents, tokens, i)
    token = tokens[nextind(tokens, i)]
    relevant_parents = if K"StandardRangedTag" ∈ parents
        k = findfirst(parents .== Ref(K"StandardRangedTag"))::Int
        parents[1:k]
    else
        parents
    end
    if kind(token) == K"Word"
        if is_nestable(first(relevant_parents)) ||
            K"Paragraph" ∈ relevant_parents ||
            K"NestableItem" ∈ relevant_parents
            MatchClosing(first(relevant_parents), false)
        else
            MatchFound(K"StrongCarryoverTag")
        end
    else
        MatchNotFound()
    end
end
