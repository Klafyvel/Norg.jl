function parse_norg(t::T, parents::Vector{Kind}, tokens::Vector{Token}, i) where {T<:AttachedModifierStrategy}
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
        segment = parse_norg(ParagraphSegment(), [node_kind, parents...], tokens, i)
        i = nextind(tokens, AST.stop(segment))
        if kind(segment) == K"None"
            append!(children, segment.children)
        else
            push!(children, segment)
        end
    end
    @debug "hey it's me" m tokens[i]
    if is_eof(tokens[i]) ||
        (isclosing(m) && matched(m) == K"None") || # Special case for inline code precedence.
        (isclosing(m) && matched(m) != node_kind && matched(m) ∈ parents) # we've been tricked in thincking we were in a modifier.
        new_children = [parse_norg(Word(), parents, tokens, start), first(children).children...]
        children[1] = AST.Node(K"ParagraphSegment", new_children, start, AST.stop(first(children)))
        i = prevind(tokens, i)
        node_kind = K"None"
    elseif isempty(children) # Empty attached modifiers are forbiddens
        children = [parse_norg(Word(), parents, tokens, start), parse_norg(Word(), parents, tokens, i)]
        node_kind = K"None"
    elseif isclosing(m) && !consume(m)
        i = prevind(tokens, i)
    elseif isclosing(m) && kind(tokens[nextind(tokens, i)]) == K":"
        i = nextind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end
