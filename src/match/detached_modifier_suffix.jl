function match_norg(::DetachedModifierSuffix, parents, tokens, i)
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    @debug "detachedmodifier match" parents next_token tokens[next_i + 1]
    if first(parents) == K"NestableItem" && kind(next_token) == K"LineEnding"
        MatchFound(K"Slide")
    elseif first(parents) == K"NestableItem" && kind(next_token) == K":"
        next_token = tokens[nextind(tokens, next_i)]
        @debug "maybe indent segment?"
        if kind(next_token) == K"LineEnding"
            @debug "Indent segment"
            MatchFound(K"IndentSegment")
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end
