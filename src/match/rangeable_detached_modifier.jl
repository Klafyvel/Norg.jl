rangeable_from_token(::Definition) = K"$"
rangeable_from_token(::Footnote) = K"^"
rangeable_from_strategy(::Definition) = K"Definition"
rangeable_from_strategy(::Footnote) = K"Footnote"

function match_norg(t::T, parents, tokens, i) where {T<:RangeableDetachedModifier}
    token = tokens[i]
    if kind(token) != rangeable_from_token(t)
        return MatchNotFound()
    end
    i = nextind(tokens, i)
    token = tokens[i]
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    if kind(token) == K"Whitespace"
        if first(parents) == K"Slide"
            MatchFound(rangeable_from_strategy(t))
        elseif (K"NestableItem" ∈ parents || AST.is_nestable(first(parents))) &&
            K"Slide" ∉ parents
            MatchClosing(first(parents), false)
        elseif !isdisjoint(parents, KSet"Paragraph ParagraphSegment")
            MatchClosing(first(parents), false)
        elseif first(parents) == rangeable_from_strategy(t)
            MatchFound(K"RangeableItem")
        else
            MatchFound(rangeable_from_strategy(t))
        end
    elseif (kind(token) == rangeable_from_token(t) && kind(next_token) == K"Whitespace")
        if first(parents) == rangeable_from_strategy(t)
            MatchFound(K"RangeableItem")
        else
            if first(parents) == K"Slide"
                MatchFound(rangeable_from_strategy(t))
            elseif (K"NestableItem" ∈ parents || AST.is_nestable(first(parents))) &&
                K"Slide" ∉ parents
                MatchClosing(first(parents), false)
            elseif !isdisjoint(parents, KSet"Paragraph ParagraphSegment")
                MatchClosing(first(parents), false)
            else
                MatchFound(rangeable_from_strategy(t))
            end
        end
    elseif kind(token) == rangeable_from_token(t) &&
        kind(next_token) == K"LineEnding" &&
        rangeable_from_strategy(t) ∈ parents
        nextline_i = consume_until(K"LineEnding", tokens, i)
        token = tokens[nextline_i]
        nextline_start_i = if kind(token) == K"Whitespace"
            nextind(tokens, nextline_i)
        else
            nextline_i
        end
        token = tokens[nextline_start_i]
        if kind(token) == rangeable_from_token(t)
            m = match_norg(t, parents, tokens, nextline_start_i)
            if isfound(m) && matched(m) == rangeable_from_strategy(t)
                MatchClosing(first(parents), true)
            else
                MatchClosing(first(parents), rangeable_from_strategy(t) == first(parents))
            end
        else
            MatchClosing(first(parents), rangeable_from_strategy(t) == first(parents))
        end
    else
        MatchNotFound()
    end
end
