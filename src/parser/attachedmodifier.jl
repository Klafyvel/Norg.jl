function parse_norg(t::T, parents::Vector{Kind}, tokens, i) where {T<:AttachedModifierStrategy}
    start = i
    children = AST.Node[]
    i = nextind(tokens, i)
    node_kind = Match.attachedmodifier(t)
    m = Match.MatchClosing(node_kind)
    while !is_eof(tokens[i])
        m = match_norg([node_kind, parents...], tokens, i)
        if isclosing(m)
            break
        end
        node = parse_norg_dispatch(matched(m), [node_kind, parents...], tokens, i)
        i = nextind(tokens, AST.stop(node))
        if kind(node) == K"None"
            append!(children, node.children)
        else
            push!(children, node)
        end
    end
    if is_eof(tokens[i])
        i = start
        children = [parse_norg(Word(), parents, tokens, start)]
        node_kind = K"None"
    elseif isclosing(m) && matched(m) == K"None"
        # Special case for inline code precedence.
        pushfirst!(children, parse_norg(Word(), parents, tokens, start))
        i = prevind(tokens, i)
        node_kind = K"None"
    elseif isclosing(m) && matched(m) != node_kind && matched(m) ∈ parents # we've been tricked in thincking we were in a modifier.
        i = start
        children = [parse_norg(Word(), parents, tokens, start)]
        node_kind = K"None"
    elseif isempty(children) # Empty attached modifiers are forbiddens
        children = [parse_norg(Word(), parents, tokens, start), parse_norg(Word(), parents, tokens, i)]
        node_kind = K"None"
    elseif isclosing(m) && !consume(m)
        i = prevind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end
