function match_norg(::Verbatim, parents, tokens, i)
    token = tokens[nextind(tokens, i)]
    if kind(token) == K"Word"
        if !(is_nestable(first(parents)) || is_heading(first(parents)) || kind(first(parents)) == K"NorgDocument")
            MatchClosing(first(parents), false)
        else
            MatchFound(K"Verbatim")
        end
    else
        MatchNotFound()
    end
end
