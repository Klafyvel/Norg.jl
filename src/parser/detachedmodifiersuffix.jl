function parse_norg(::Slide, parents::Vector{Kind}, tokens::Vector{Token}, i)
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

function parse_norg(::IndentSegment, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = consume_until(K"LineEnding", tokens, i)    
    p = [K"IndentSegment", parents...]
    m = Match.MatchClosing(K"IndentSegment")
    children = []

    while !is_eof(tokens[i])
        m = match_norg(p, tokens, i)
        @debug "indent segment loop" m tokens[i]
        if isclosing(m)
            break
        elseif iscontinue(m)
            i = nextind(tokens, i)
            continue
        end
        to_parse = matched(m)
        if to_parse == K"WeakDelimitingModifier"
            start_del = i
            i = prevind(tokens, consume_until(K"LineEnding", tokens, i))
            push!(children, AST.Node(K"WeakDelimitingModifier", AST.Node[], start_del, i))
            break
        elseif kind(to_parse) == K"StrongDelimitingModifier"
            i = prevind(tokens, i)
            break
        elseif kind(to_parse) == K"HorizontalRule"
            start_hr = i
            stop_hr = consume_until(K"LineEnding", tokens, i)
            child = AST.Node(to_parse, AST.Node[], start_hr, stop_hr)
            break
        elseif is_quote(to_parse)
            child = parse_norg(Quote(), p, tokens, i)
        elseif is_unordered_list(to_parse)
            child = parse_norg(UnorderedList(), p, tokens, i)
        elseif is_ordered_list(to_parse)
            child = parse_norg(OrderedList(), p, tokens, i)
        elseif kind(to_parse) == K"Verbatim"
            child = parse_norg(Verbatim(), p, tokens, i)
        elseif to_parse == K"WeakCarryoverTag"
            child = parse_norg(WeakCarryoverTag(), parents, tokens, i)
        elseif to_parse == K"StrongCarryoverTag"
            child = parse_norg(StrongCarryoverTag(), parents, tokens, i)
        elseif to_parse == K"Definition"
            child = parse_norg(Definition(), parents, tokens, i)
        elseif to_parse == K"Footnote"
            child = parse_norg(Footnote(), parents, tokens, i)
        else
            child = parse_norg(Paragraph(), p, tokens, i)
        end
        i = AST.stop(child)
        if !is_eof(tokens[i])
            i = nextind(tokens, AST.stop(child))
        end
        if kind(child) == K"None"
            append!(children, child.children)
        else
            push!(children, child)
        end
    end
    if isclosing(m) && !(matched(m) == K"IndentSegment" && consume(m))
        i = prevind(tokens, i)
    end
    AST.Node(K"IndentSegment", children, start, i)
end
