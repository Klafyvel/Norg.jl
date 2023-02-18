rangeable_from_token(::Definition) = K"$"
rangeable_from_token(::Footnote) = K"^"
rangeable_from_strategy(::Definition) = K"Definition"
rangeable_from_strategy(::Footnote) = K"Footnote"

function match_norg(t::T, parents, tokens, i) where {T<:RangeableDetachedModifier}
    token = tokens[i]
    @debug "okay, matching rangeable" token
    if kind(token) != rangeable_from_token(t)
        return MatchNotFound()
    end
    i = nextind(tokens, i)
    token = tokens[i]
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    if kind(token) == K"Whitespace"
        @debug "haha, whitespace" parents
        if first(parents) == K"Slide"
            MatchFound(rangeable_from_strategy(t))
        elseif (K"NestableItem" ∈ parents || AST.is_nestable(first(parents))) && K"Slide" ∉ parents
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
            elseif (K"NestableItem" ∈ parents || AST.is_nestable(first(parents))) && K"Slide" ∉ parents
                MatchClosing(first(parents), false)
            elseif !isdisjoint(parents, KSet"Paragraph ParagraphSegment")
                MatchClosing(first(parents), false)
            else
                MatchFound(rangeable_from_strategy(t))
            end
        end
    elseif kind(token) == rangeable_from_token(t) && kind(next_token) == K"LineEnding" && rangeable_from_strategy(t) ∈ parents
        @debug "match ending ranged"
        nextline_i = consume_until(K"LineEnding", tokens, i)
        token = tokens[nextline_i]
        nextline_start_i = if kind(token) == K"Whitespace"
            nextind(tokens, nextline_i)
        else
            nextline_i
        end
        token = tokens[nextline_start_i]
        @debug "next line starts with" token
        if kind(token) == rangeable_from_token(t)
            @debug "start matching the next line"
            m = match_norg(t, parents, tokens, nextline_start_i)
            @debug "stop matching the next line"
            @debug "it matches a" m first(parents) rangeable_from_strategy(t)
            if isfound(m) && matched(m)==rangeable_from_strategy(t) 
                @debug "Let's close the current RangeableItem"
                MatchClosing(first(parents), true)
            else
                MatchClosing(first(parents), rangeable_from_strategy(t)==first(parents))
            end
        else
            @debug "so we close first parent" first(parents) rangeable_from_strategy(t)
            MatchClosing(first(parents), rangeable_from_strategy(t)==first(parents))
        end
    else
        MatchNotFound()
    end
end
