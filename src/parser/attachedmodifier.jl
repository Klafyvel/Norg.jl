function parse_norg(t::T, parents::Vector{Kind}, tokens, i) where {T<:AttachedModifierStrategy}
    start = i
    children = AST.Node[]
    i = nextind(tokens, i)
    node_kind = Match.attachedmodifier(t)
    m = Match.MatchClosing(node_kind)
    while i <= lastindex(tokens)
        m = match_norg([node_kind, parents...], tokens, i)
        # @debug "attached modifier loop" node_kind token m
        if isclosing(m)
            break
        end
        node = parse_norg_dispatch(matched(m), [node_kind, parents...], tokens, i)
        i = nextind(tokens, AST.stop(node))
        push!(children, node)
    end
    if isclosing(m) && matched(m) != node_kind && matched(m) ∈ parents # we've been tricked in thincking we were in a modifier.
        pushfirst!(children, parse_norg(Word(), parents, tokens, start))
        node_kind = K"None"
    elseif isempty(children) # Empty attached modifiers are forbiddens
        children = [parse_norg(Word(), parents, tokens, start), parse_norg(Word(), parents, tokens, i)]
        node_kind = K"None"
    elseif isclosing(m) && consume(m)
        i = nextind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end
