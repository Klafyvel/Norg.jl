function parse_norg(::T, parents, tokens, i) where {T<:Nestable}
    start = i
    # TODO: This is innefficient because this match has already been done at this
    # point, so we could transmit the information through the strategy. But this
    # is a small overcost and I'm being lazy ;)
    nestable_match = match_norg(parents, tokens, i)
    nestable_kind = matched(nestable_match)
    children = AST.Node[]
    while !is_eof(tokens[i])
        m = match_norg([nestable_kind, parents...], tokens, i)
        if isclosing(m)
            if !consume(m)
                i = prevind(tokens, i)
            end
            break
        end
        child = parse_norg(NestableItem(), [nestable_kind, parents...], tokens, i)
        i = AST.stop(child)
        if !is_eof(tokens[i])
            i = nextind(tokens, i)
        end
        push!(children, child)
    end
    AST.Node(nestable_kind, children, start, i)
end

function parse_norg(::NestableItem, parents, tokens, i)
    start = i
    token = tokens[i]
    children = AST.Node[]
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = tokens[i]
    end
    # Consume tokens creating the delimiter
    i = consume_until(K"Whitespace", tokens, i)
    while !is_eof(tokens[i])
        m = match_norg([K"NestableItem", parents...], tokens, i)
        if isclosing(m)
            if !consume(m)
                i = prevind(tokens, i)
            end
            break
        end
        to_parse = matched(m)
        if to_parse == K"Verbatim"
            child = parse_norg(Verbatim(), [K"NestableItem", parents...], tokens, i)
        elseif is_quote(to_parse)
            child = parse_norg(Quote(), [K"NestableItem", parents...], tokens, i) 
        elseif is_unordered_list(to_parse)
            child = parse_norg(UnorderedList(), [K"NestableItem", parents...], tokens, i) 
        elseif is_ordered_list(to_parse)
            child = parse_norg(OrderedList(), [K"NestableItem", parents...], tokens, i) 
        else
            child = parse_norg(Paragraph(), [K"NestableItem", parents...], tokens, i)
        end
        i = nextind(tokens, AST.stop(child))
        push!(children, child)
    end
    if is_eof(tokens[i])
        i = lastindex(tokens)
    end
    AST.Node(K"NestableItem", children, start, i)
end
