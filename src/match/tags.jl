function match_norg(::Verbatim, parents, tokens, i)
    token = tokens[nextind(tokens, i)]
    @debug "verbatim match" parents tokens[i]
    if kind(token) == K"Word"
        if kind(first(parents)) ∈ KSet"Slide IndentSegment"
            MatchFound(K"Verbatim")
        elseif !(is_nestable(first(parents)) || is_heading(first(parents)) || kind(first(parents)) == K"NorgDocument") 
            MatchClosing(first(parents), false)
        else
            MatchFound(K"Verbatim")
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
    if kind(token) == K"Word"
        nextline = consume_until(K"LineEnding", tokens, i)
        m = match_norg(parents, tokens, nextline)
        if isclosing(m)
            m
        elseif is_nestable(first(parents)) || K"Paragraph" ∈ parents
            MatchClosing(first(parents), false)
        else
            MatchFound(K"StrongCarryoverTag")
        end
    else
        MatchNotFound()
    end
end
