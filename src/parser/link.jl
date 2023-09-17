limit_tokens(tokens, stop) = [tokens[begin:stop]...; EOFToken()]::Vector{Token}


function parse_norg(::Link, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    if is_eof(token)
        return parse_norg(Word(), parents, tokens, i)
    end
    location_node = parse_norg(LinkLocation(), [K"Link", parents...], tokens, i)
    if kind(location_node) == K"None"
        w = parse_norg(Word(), parents, tokens, prevind(tokens, i))
        c = [w, location_node.children...]
        return AST.Node(K"None", c, start, location_node.stop)
    end
    i = nextind(tokens, AST.stop(location_node))
    token = tokens[i]
    if is_eof(token)
        i = prevind(tokens, i)
        return AST.Node(K"Link", AST.Node[location_node], start, i)
    end
    description_match = match_norg(LinkDescription(), [K"Link", parents...], tokens, i)
    if isclosing(description_match)
        if !consume(description_match)
            i = prevind(tokens, i)
        end
        return AST.Node(K"Link", AST.Node[location_node], start, i)
    end
    if kind(matched(description_match)) == K"LinkDescription"
        description_node = parse_norg(LinkDescription(), parents, tokens, i)
    else
        error("Expecting a link description at $(tokens[i])")
    end
    i = AST.stop(description_node)
    if kind(description_node) == K"None"
        l = AST.Node(K"Link", [location_node], start, i)
        AST.Node(K"None", [l, description_node.children...], start, i)
    else
        AST.Node(K"Link", [location_node, description_node], start, i)
    end
end

function parse_norg(::LinkLocation, parents::Vector{Kind}, tokens::Vector{Token}, i)
    location_match = match_norg(LinkLocation(), parents, tokens, i)
    location_kind = kind(matched(location_match))
    p = [K"LinkLocation"; parents...]

    if location_kind == K"URLLocation"
        parse_norg(URLLocation(), p, tokens, i)
    elseif location_kind == K"LineNumberLocation"
        parse_norg(LineNumberLocation(), p, tokens, i)
    elseif location_kind == K"DetachedModifierLocation"
        parse_norg(DetachedModifierLocation(), p, tokens, i)
    elseif location_kind == K"FileLocation"
        parse_norg(FileLocation(), p, tokens, i)
    elseif location_kind == K"MagicLocation"
        parse_norg(MagicLocation(), p, tokens, i)
    elseif location_kind == K"NorgFileLocation"
        parse_norg(NorgFileLocation(), p, tokens, i)
    elseif location_kind == K"WikiLocation"
        parse_norg(WikiLocation(), p, tokens, i)
    elseif location_kind == K"TimestampLocation"
        parse_norg(TimestampLocation(), p, tokens, i)
    else
        AST.Node(K"None")
    end
end

function parse_norg(::URLLocation, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    token = tokens[i]
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m)
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m)
        i = prevind(tokens, i)
    end
    if isclosing(m) && matched(m) != K"URLLocation" && kind(token) != K"}"
        p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)
        AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
    else
        stop = i
        i = prevind(tokens, i)
        AST.Node(K"URLLocation", [AST.Node(K"URLTarget", AST.Node[], start, i)], start, stop)
    end
end

function parse_norg(::LineNumberLocation, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    token = tokens[i]
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m)
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    if isclosing(m) && matched(m) != K"LineNumberLocation" && kind(token) != K"}"
        p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)

        AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
    else
        stop = i
        i = prevind(tokens, i)
        AST.Node(K"LineNumberLocation", [AST.Node(K"LineNumberTarget", AST.Node[], start, i)], start, stop)
    end
end

function parse_norg(::DetachedModifierLocation, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    token = tokens[i]
    if kind(token) == K"*"
        level = 0
        while kind(token) == K"*"
            level += 1
            i = nextind(tokens, i)
            token = tokens[i]
        end
        if kind(token) == K"Whitespace"
            i = nextind(tokens, i)
            token = tokens[i]
        end
        heading_kind = if level == 1
            K"Heading1"
        elseif level == 2
            K"Heading2"
        elseif level == 3
            K"Heading3"
        elseif level == 4
            K"Heading4"
        elseif level == 5
            K"Heading5"
        else # level >= 6
            K"Heading6"
        end
    elseif kind(token) == K"$"
        heading_kind = K"Definition"
        i = consume_until(K"Whitespace", tokens, i)
    elseif kind(token) == K"^"
        heading_kind = K"Footnote"
        i = consume_until(K"Whitespace", tokens, i)
    else
        error("Wrong detached modifier link at token $token")
    end

    start_heading_title = i
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m)
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start_heading_title)
    if kind(token) == K"}"
        children = AST.Node[]
        for (i,c) in enumerate(p.children)
            append!(children, c.children)
            if i < lastindex(p.children)
                push!(children, AST.Node(K"WordNode", AST.Node[], c.stop, c.stop))
            end
        end
        content = AST.Node(K"ParagraphSegment", children, p.start, p.stop)
        AST.Node(K"DetachedModifierLocation", [AST.Node(heading_kind), content], start, i)
    else
        c = [AST.Node(K"WordNode", [], j, j) for j ∈ start:(p.start-1)]
        children = p.children
        ps = AST.Node(K"ParagraphSegment", AST.Node[c...;children[1].children...], start, children[1].stop)
        children[1] = ps
        AST.Node(K"None", children, start, i)
    end
end

function parse_norg(::MagicLocation, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_heading_title = i
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m)
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start_heading_title)
    if kind(token) == K"}"
        children = AST.Node[]
        for (i,c) in enumerate(p.children)
            append!(children, c.children)
            if i < lastindex(p.children)
                push!(children, AST.Node(K"WordNode", [], c.stop, c.stop))
            end
        end
        content = AST.Node(K"ParagraphSegment", children, p.start, p.stop)
        AST.Node(K"MagicLocation", [content], start, i)
    else
        c = [AST.Node(K"WordNode", [], j, j) for j ∈ start:(p.start-1)]
        children = p.children
        ps = AST.Node(K"ParagraphSegment", AST.Node[c...;children[1].children...], start, children[1].stop)
        children[1] = ps
        AST.Node(K"None", children, start, i)
    end
end

filelocationkind(::FileLocation) = K"FileLocation"
filelocationkind(::NorgFileLocation) = K"NorgFileLocation"
function parse_norg(t::T, parents::Vector{Kind}, tokens::Vector{Token}, i,) where { T <: Union{FileLocation, NorgFileLocation}}
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    use_neorg_root = false
    if kind(token) == K"$"
        i = nextind(tokens, i)
        token = tokens[i]
        use_neorg_root = true
    end
    start_location = i
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m) && kind(token) != K":"
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    if isclosing(m) && matched(m) != filelocationkind(t) && kind(token) != K"}"
        p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)

        return AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
    end
    if use_neorg_root
        k = K"FileNorgRootTarget"
    else
        k = K"FileTarget"
    end
    file_target = AST.Node(k, AST.Node[], start_location, prevind(tokens, i))
    subtarget = AST.Node(K"None")
    if kind(token) == K":"
        i = nextind(tokens, i)
        token = tokens[i]
        subtarget = parse_norg(LinkLocation(), [filelocationkind(t), parents...], tokens, i)
        if kind(subtarget) == K"None"
            m = match_norg(parents, tokens, i)
            while !is_eof(token) && !isclosing(m)
                i = nextind(tokens, i)
                token = tokens[i]
                m = match_norg(parents, tokens, i)
            end
            if !consume(m) || is_eof(token)
                i = prevind(tokens, i)
            end
            if isclosing(m) && matched(m) != filelocationkind(t) && kind(token) != K"}"
                p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)
                return AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
            end
        else
            i = AST.stop(subtarget)
            # subtarget = first(children(subtarget))
        end
    end
    AST.Node(filelocationkind(t), [file_target, subtarget], start, i)
end

function parse_norg(::WikiLocation, parents::Vector{Kind}, tokens::Vector{Token}, i,)
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_heading_title = i
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m) && kind(token) != K":"
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start_heading_title)
    subtarget = AST.Node(K"None")
    content = AST.Node(K"None")
    if kind(token) ∈ KSet"} :"
        children = AST.Node[]
        for (i,c) in enumerate(p.children)
            append!(children, c.children)
            if i < lastindex(p.children)
                push!(children, AST.Node(K"WordNode", [], c.stop, c.stop))
            end
        end
        content = AST.Node(K"ParagraphSegment", children, p.start, p.stop)
    else
        c = [AST.Node(K"WordNode", [], j, j) for j ∈ start:(p.start-1)]
        children = p.children
        ps = AST.Node(K"ParagraphSegment", AST.Node[c...;children[1].children...], start, children[1].stop)
        children[1] = ps
        return AST.Node(K"None", children, start, i)
    end
    if kind(token) == K":"
        subtarget = parse_norg(LinkLocation(), [K"WikiLocation", parents...], tokens, i)
        if kind(subtarget) == K"None"
            m = match_norg(parents, tokens, i)
            while !is_eof(token) && !isclosing(m)
                i = nextind(tokens, i)
                token = tokens[i]
                m = match_norg(parents, tokens, i)
            end
            if !consume(m) || is_eof(token)
                i = prevind(tokens, i)
            end
            if isclosing(m) && matched(m) != K"WikiLocation" && kind(token) != K"}"
                p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)
                return AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
            end
        else
            i = AST.stop(subtarget)
        end
    end
    AST.Node(K"WikiLocation", [content, subtarget], start, i)
end


function parse_norg(::TimestampLocation, parents::Vector{Kind}, tokens::Vector{Token}, i,)
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_timestamp=i
    m = match_norg(parents, tokens, i)
    while !is_eof(token) && !isclosing(m)
        i = nextind(tokens, i)
        token = tokens[i]
        m = match_norg(parents, tokens, i)
    end
    if !consume(m) || is_eof(token)
        i = prevind(tokens, i)
    end
    if isclosing(m) && matched(m) != K"TimestampLocation" && kind(token) != K"}"
        p = parse_norg(Paragraph(), parents, limit_tokens(tokens, i), start)
        AST.Node(K"None", vcat([c.children for c in p.children]...), start, i)
    else
        stop = i
        i = prevind(tokens, i)
        AST.Node(K"TimestampLocation", [AST.Node(K"Timestamp", AST.Node[], start_timestamp, i)], start, stop)
    end
end

function parse_norg(::LinkDescription, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    children = AST.Node[]
    m = Match.MatchClosing(K"LinkDescription")
    while !is_eof(tokens[i])
        m = match_norg([K"LinkDescription", parents...], tokens, i)
        if isclosing(m)
            break
        end
        segment = parse_norg(ParagraphSegment(), [K"LinkDescription", parents...], tokens, i)
        i = nextind(tokens, AST.stop(segment))
        if kind(segment) == K"None"
            append!(children, segment.children)
        else
            push!(children, segment)
        end
    end
    node_kind = K"LinkDescription"
    if is_eof(tokens[i]) ||
        (isclosing(m) && matched(m) != K"LinkDescription" && matched(m) ∈ parents) || # we've been tricked in thincking we were in a link description
        (isclosing(m) && kind(tokens[i]) != K"]")
        new_children = [parse_norg(Word(), parents, tokens, start), first(children).children...]
        children[1] = AST.Node(K"ParagraphSegment", new_children, start, AST.stop(first(children)))
        i = prevind(tokens, i)
        node_kind = K"None"
    elseif isclosing(m) && !consume(m)
        i = prevind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end

function parse_norg(::Anchor, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    description_node = parse_norg(LinkDescription(), [K"Anchor", parents...], tokens, i)
    if kind(description_node) == K"None"
        return description_node
    end
    i = AST.stop(description_node)
    i = nextind(tokens, i)
    token = tokens[i]
    if is_eof(token) || kind(token) != K"{"
        i = prevind(tokens, i)
        return AST.Node(K"Anchor", [description_node], start, i)
    else
        i = nextind(tokens, i)
        token = tokens[i]
    end
    location_node = parse_norg(LinkLocation(), [K"Anchor", parents...], tokens, i)
    if kind(location_node) == K"None"
        w = parse_norg(Word(), parents, tokens, prevind(tokens, i))
        l = AST.Node(K"Anchor", [description_node], start, description_node.stop)
        c = [l, w, location_node.children...]
        AST.Node(K"None", c, start, location_node.stop)
    else
        i = AST.stop(location_node)
        AST.Node(K"Anchor", [description_node, location_node], start, i)
    end
end

function parse_norg(::InlineLinkTarget, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    children = AST.Node[]
    m = Match.MatchClosing(K"InlineLinkTarget")
    while !is_eof(tokens[i])
        m = match_norg([K"InlineLinkTarget", parents...], tokens, i)
        if isclosing(m)
            break
        end
        segment = parse_norg(ParagraphSegment(), [K"InlineLinkTarget", parents...], tokens, i)
        i = nextind(tokens, AST.stop(segment))
        if kind(segment) == K"None"
            append!(children, segment.children)
        else
            push!(children, segment)
        end
    end
    node_kind = K"InlineLinkTarget"
    if is_eof(tokens[i]) ||
        (isclosing(m) && matched(m) != K"InlineLinkTarget" && matched(m) ∈ parents) || # we've been tricked in thincking we were in a link description
        (isclosing(m) && kind(tokens[i]) != K">")
        new_children = [parse_norg(Word(), parents, tokens, start), first(children).children...]
        children[1] = AST.Node(K"ParagraphSegment", new_children, start, AST.stop(first(children)))
        i = prevind(tokens, i)
        node_kind = K"None"
    elseif isclosing(m) && !consume(m)
        i = prevind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end
