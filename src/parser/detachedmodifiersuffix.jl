function parse_norg(::Slide, parents, tokens, i)
    start = i
    i = consume_until(K"LineEnding", tokens, i)    
    p = [K"Slide", parents...]
    m = match_norg(p, tokens, i)
    @debug "ok fréro j'ai ça." tokens[i] m
    child = if isfound(m)
        if matched(m) == K"Definition"
            parse_norg(Definition(), p, tokens, i)
        elseif matched(m) == K"Footnote"
            parse_norg(Footnote(), p, tokens, i)
        elseif matched(m) == K"Verbatim"
            parse_norg(Verbatim(), p, tokens, i)
        else
            parse_norg(Paragraph(), p, tokens, i)
        end
    else
        parse_norg(parents, tokens, i)
    end
    AST.Node(K"Slide", [child], start, AST.stop(child))
end
