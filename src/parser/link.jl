function parse_norg(::Link, parents, tokens, i)
    start = i
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "Welcome in link parsing"
    if isnothing(token)
        @debug "nah"
        return parse_norg(Word(), parents, tokens, i)
    end
    location_node = parse_norg(LinkLocation(), [K"Link", parents...], tokens, i)
    i = nextind(tokens, AST.stop(location_node))
    token = get(tokens, i, nothing)
    @debug "Got the location" location_node token
    if isnothing(token)
        i = prevind(tokens, i)
        return AST.Node(K"Link", AST.Node[location_node], start, i)
    end
    description_match = match_norg(LinkDescription(), [K"Link", parents...], tokens, i)
    @debug "This matches" description_match
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
    AST.Node(K"Link", [location_node, description_node], start, i)
end

function parse_norg(::LinkLocation, parents, tokens, i)
    location_match = match_norg(LinkLocation(), parents, tokens, i)
    location_kind = kind(matched(location_match))

    if location_kind == K"URLLocation"
        parse_norg(URLLocation(), parents, tokens, i)
    elseif location_kind == K"LineNumberLocation"
        parse_norg(LineNumberLocation(), parents, tokens, i)
    elseif location_kind == K"DetachedModifierLocation"
        parse_norg(DetachedModifierLocation(), parents, tokens, i)
    elseif location_kind == K"FileLocation"
        parse_norg(FileLocation(), parents, tokens, i)
    elseif location_kind == K"MagicLocation"
        parse_norg(MagicLocation(), parents, tokens, i)
    elseif location_kind == K"NorgFileLocation"
        parse_norg(NorgFileLocation(), parents, tokens, i)
    else
        AST.Node(K"None")
    end
end

function parse_norg(::URLLocation, parents, tokens, i)
    start = i
    token = get(tokens, i, nothing)
    while !isnothing(token) && kind(token) ∉ [K"}", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if kind(token) == K"}"
        stop = i
        i = prevind(tokens, i)
    else
        i = prevind(tokens, i)
        stop = i         
    end
    AST.Node(K"URLLocation", [AST.Node(K"URLTarget", AST.Node[], start, i)], start, stop)
end

function parse_norg(::LineNumberLocation, parents, tokens, i)
    start = i
    token = get(tokens, i, nothing)
    while !isnothing(token) && kind(token) ∉ [K"}", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if kind(token) == K"}"
        stop = i
        i = prevind(tokens, i)
    else
        i = prevind(tokens, i)
        stop = i         
    end
    AST.Node(K"LineNumberLocation", [AST.Node(K"LineNumberTarget", AST.Node[], start, i)], start, stop)
end

function parse_norg(::DetachedModifierLocation, parents, tokens, i)
    start = i
    token = get(tokens, i, nothing)
    level = 0
    while kind(token) == K"*"
        level += 1
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
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
    elseif level >= 6
        K"Heading6"
    end
    start_heading_title = i
    #TODO: this should be replaced with consume_until and a Kset""
    while !isnothing(token) && kind(token) ∉ [K"}", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    i = prevind(tokens, i)
    content = parse_norg(ParagraphSegment(), [K"DetachedModifierLocation", parents...], tokens[begin:i], start_heading_title)
    if kind(token) == K"}"
        i = nextind(tokens, i)
    end
    AST.Node(K"DetachedModifierLocation", [AST.Node(heading_kind), content], start, i)
end

function parse_norg(::MagicLocation, parents, tokens, i)
    start = i
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    start_heading_title = i
    while !isnothing(token) && kind(token) ∉ [K"}", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    i = prevind(tokens, i)
    content = parse_norg(ParagraphSegment(), [K"MagicLocation", parents...], tokens[begin:i], start_heading_title)
    if kind(token) == K"}"
        i = nextind(tokens, i)
    end
    AST.Node(K"MagicLocation", [content], start, i)
end

filelocationkind(::FileLocation) = K"FileLocation"
filelocationkind(::NorgFileLocation) = K"NorgFileLocation"
function parse_norg(t::T, parents, tokens, i,) where { T <: Union{FileLocation, NorgFileLocation}}
    start = i
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "file link parsing" token
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    use_neorg_root = false
    if kind(token) == K"$"
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        use_neorg_root = true
    end
    start_location = i
    while !isnothing(token) && kind(token) ∉ [K"}", K":", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
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
        token = get(tokens, i, nothing)
        subtarget = parse_norg(LinkLocation(), [filelocationkind(t), parents...], tokens, i)
        if kind(subtarget) == K"None"
            while !isnothing(token) && kind(token) ∉ [K"LineEnding", K"}"]
                i = nextind(tokens, i)
                token = get(tokens, i, nothing)
            end
            if kind(token) != K"}"
                i = prevind(tokens, i)
            end
        else
            i = AST.stop(subtarget)
            # subtarget = first(children(subtarget))
        end
    end
    AST.Node(filelocationkind(t), [file_target, subtarget], start, i)
end

function parse_norg(::LinkDescription, parents, tokens, i)
    start = i
    token = get(tokens, i, nothing)
    if kind(token) == K"["
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    start_content = i
    while !isnothing(token) && kind(token) ∉ [K"]", K"LineEnding"]
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    i = prevind(tokens, i)
    content = parse_norg(ParagraphSegment(), parents, tokens[begin:i], start_content) 
    if kind(token) == K"]"
        i = nextind(tokens, i)
    end
    AST.Node(K"LinkDescription", [content], start, i)
end

function parse_norg(::Anchor, parents, tokens, i)
    start = i
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "Welcome in anchor parsing"
    if isnothing(token)
        @debug "nah"
        return parse_norg(Word(), parents, tokens, i)
    end
    description_node = parse_norg(LinkDescription(), [K"Anchor", parents...], tokens, i)
    i = AST.stop(description_node)
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "Got the description" description_node token
    if isnothing(token) || kind(token) != K"{"
        @debug "Goodbye"
        i = prevind(tokens, i)
        return AST.Node(K"Anchor", [description_node], start, i)
    else
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    location_node = parse_norg(LinkLocation(), [K"Anchor", parents...], tokens, i)
    i = AST.stop(location_node)
    AST.Node(K"Anchor", [description_node, location_node], start, i)
end
