function match_norg(::LinkLocation, parents, tokens, i)
    if kind(tokens[i]) == K"}"
        MatchFound(K"None")
    elseif kind(tokens[i]) == K":"
        MatchFound(K"NorgFileLocation")
    elseif kind(tokens[i]) == K"#"
        MatchFound(K"MagicLocation")
    elseif kind(tokens[i]) == K"/"
        MatchFound(K"FileLocation")
    elseif kind(tokens[i]) ∈ KSet"* $ ^"
        MatchFound(K"DetachedModifierLocation")
    elseif kind(tokens[i]) == K"?"
        MatchFound(K"WikiLocation")
    elseif kind(tokens[i]) == K"@"
        MatchFound(K"TimestampLocation")
    elseif isnumeric(first(value(tokens[i])))
        MatchFound(K"LineNumberLocation")
    else
        MatchFound(K"URLLocation")
    end
end

function match_norg(::LinkDescription, parents, tokens, i)
    if kind(tokens[i]) == K"[" && kind(tokens[nextind(tokens, i)]) != K"LineEnding"
        MatchFound(K"LinkDescription")
    elseif first(parents) == K"Link"
        MatchClosing(K"Link", false)
    else
        MatchNotFound()
    end
end

function match_norg(::LinkSubTarget, parents, tokens, i)
    if kind(first(parents)) == K"FileLocation" 
        if isnumeric(first(value(tokens[i])))
            MatchFound(K"LineNumberLocation")
        else
            MatchNotFound()
        end
    elseif kind(first(parents)) == K"NorgFileLocation"
        if kind(tokens[i]) == K"*"
            MatchFound(K"DetachedModifierLocation")
        elseif kind(tokens[i]) == K"#"
            MatchFound(K"MagicLocation")
        elseif isnumeric(first(value(tokens[i])))
            MatchFound(K"LineNumberLocation")
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end

function match_norg(::Anchor, parents, tokens, i)
    if kind(tokens[i]) == K"[" && kind(tokens[nextind(tokens, i)]) != K"LineEnding"
        MatchFound(K"Anchor")
    else
        MatchNotFound()
    end
end

function match_norg(::InlineLinkTarget, parents, tokens, i)
    if kind(tokens[i]) == K"<" && kind(tokens[nextind(tokens, i)]) != K"LineEnding"
        MatchFound(K"InlineLinkTarget")
    else
        MatchNotFound()
    end
end
