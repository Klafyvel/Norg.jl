function match_norg(::DetachedModifierSuffix, parents, tokens, i)
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    if first(parents) == K"NestableItem" && kind(next_token) == K"LineEnding"
        MatchFound(K"Slide")
    elseif first(parents) == K"NestableItem" && kind(next_token) == K":"
        next_token = tokens[nextind(tokens, next_i)]
        if kind(next_token) == K"LineEnding"
            MatchFound(K"IndentSegment")
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end
