function match_norg(::DetachedModifierExtension, parents, tokens, i)
    token = tokens[nextind(tokens, i)]
    if kind(token) == K"#"
        MatchFound(K"PriorityExtension")
    elseif kind(token) == K"<"
        MatchFound(K"DueDateExtension")
    elseif kind(token) == K">"
        MatchFound(K"StartDateExtension")
    elseif kind(token) == K"@"
        MatchFound(K"TimestampExtension")
    elseif kind(token) ∈ KSet"Whitespace x ? ! + - = _"
        MatchFound(K"TodoExtension")
    else
        MatchNotFound()
    end
end
