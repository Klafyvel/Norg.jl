function parse_norg(::Type{AST.Link}, tokens, i, parents)
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "Welcome in link parsing"
    if isnothing(token)
        @debug "nah"
        return parse_norg(AST.Word, tokens, i, parents)
    end
    location_match = match_norg(AST.LinkLocation, token, [AST.Link, parents...],
                                tokens, i)
    i, location_node = parse_norg(matched(location_match), tokens, i,
                                  [AST.Link, parents...])
    token = get(tokens, i, nothing)
    @debug "Got the location" location_match location_node token
    if isnothing(token)
        return i, AST.Node(AST.Node[location_node], AST.Link())
    end
    description_match = match_norg(AST.LinkDescription, token,
                                   [AST.Link, parents...], tokens, i)
    @debug "This matches" description_match
    if isclosing(description_match)
        if description_match.consume
            i = nextind(tokens, i)
        end
        return i, AST.Node(AST.Node[location_node], AST.Link())
    end
    i, description_node = parse_norg(matched(description_match), tokens, i,
                                     [AST.Link, parents...])
    i, AST.Node(AST.Node[location_node, description_node], AST.Link())
end

function parse_norg(::Type{AST.URLLocation}, tokens, i, parents)
    content = String[]
    token = get(tokens, i, nothing)
    while !isnothing(token) && !isa(token, Token{Tokens.RightBrace}) &&
              !isa(token, Token{Tokens.LineEnding})
        push!(content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content_str = join(content)
    if token isa Token{Tokens.RightBrace}
        i = nextind(tokens, i)
    end
    i, AST.Node(AST.Node[], AST.URLLocation(content_str))
end

function parse_norg(::Type{AST.LineNumberLocation}, tokens, i, parents)
    content = String[]
    token = get(tokens, i, nothing)
    while !isnothing(token) && !isa(token, Token{Tokens.RightBrace}) &&
              !isa(token, Token{Tokens.LineEnding})
        push!(content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content_str = join(content)
    lineno = tryparse(Int, content_str)
    if token isa Token{Tokens.RightBrace}
        i = nextind(tokens, i)
    end
    if isnothing(lineno) # we were fed a strange string that starts with a number, but is not a number. Fallback to an URL.
        i, AST.Node(AST.Node[], AST.URLLocation(content_str))
    else
        i, AST.Node(AST.Node[], AST.LineNumberLocation(lineno))
    end
end

function parse_norg(::Type{AST.DetachedModifierLocation}, tokens, i, parents)
    token = get(tokens, i, nothing)
    level = 0
    while token isa Token{Tokens.Star}
        level += 1
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if token isa Token{Tokens.Whitespace}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content = String[]
    while !isnothing(token) && !isa(token, Token{Tokens.RightBrace}) &&
              !isa(token, Token{Tokens.LineEnding})
        push!(content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content_str = join(content)
    if token isa Token{Tokens.RightBrace}
        i = nextind(tokens, i)
    end
    i, AST.Node(AST.Node[], AST.DetachedModifierLocation(content_str, level))
end

function parse_norg(::Type{AST.MagicLocation}, tokens, i, parents)
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    if token isa Token{Tokens.Whitespace}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content = String[]
    while !isnothing(token) && !isa(token, Token{Tokens.RightBrace}) &&
              !isa(token, Token{Tokens.LineEnding})
        push!(content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content_str = join(content)
    if token isa Token{Tokens.RightBrace}
        i = nextind(tokens, i)
    end
    i, AST.Node(AST.Node[], AST.MagicLocation(content_str))
end

function parse_norg(::Type{T}, tokens, i,
                    parents) where {
                                    T <: Union{AST.FileLinkableLocation,
                                          AST.FileLocation}}
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    if token isa Token{Tokens.Whitespace}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    use_neorg_root = false
    if token isa Token{Tokens.DollarSign}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        use_neorg_root = true
    end
    content = String[]
    while !isnothing(token) && !isa(token, Token{Tokens.RightBrace}) &&
              !isa(token, Token{Tokens.LineEnding}) &&
              !isa(token, Token{Tokens.Colon})
        push!(content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    content_str = join(content)
    subtarget = nothing
    if token isa Token{Tokens.RightBrace}
        i = nextind(tokens, i)
    elseif token isa Token{Tokens.Colon}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        match = match_norg(T, AST.LinkDescription, token, tokens, i,
                           [T, parents...])
        if match isa Match.MatchFound
            i, subtarget = parse_norg(matched(match), tokens, i,
                                      [T, parents...])
        else
            while !isnothing(token) && !isa(token, Token{Tokens.LineEnding}) &&
                      !isa(token, Token{Tokens.RightBrace})
                i = nextind(tokens, i)
                token = get(tokens, i, nothing)
            end
        end
        if token isa Token{Tokens.RightBrace}
            i = nextind(tokens, i)
        end
    end
    i, AST.Node(AST.Node[], T(use_neorg_root, content_str, subtarget))
end

function parse_norg(::Type{AST.LinkDescription}, tokens, i, parents)
    token = get(tokens, i, nothing)
    if token isa Token{Tokens.LeftSquareBracket}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    children = AST.Node[]
    while !isnothing(token)
        token = tokens[i]
        m = match_norg(token, [AST.LinkDescription, parents...], tokens, i)
        if isclosing(m)
            break
        end
        i, node = parse_norg(matched(m), tokens, i,
                             [AST.LinkDescription, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        else
            push!(children, node)
        end
        if token isa Token{Tokens.RightBrace}
            i = nextind(tokens, i)
        end
    end
    if i > lastindex(tokens) || tokens[i] isa Tokens.LineEnding
        i, children
    else
        i = nextind(tokens, i)
        i, AST.Node(children, AST.LinkDescription())
    end
end

function parse_norg(::Type{AST.Anchor}, tokens, i, parents)
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "Welcome in anchor parsing"
    if isnothing(token)
        @debug "nah"
        return parse_norg(AST.Word, tokens, i, parents)
    end
    i, description_node = parse_norg(AST.LinkDescription, tokens, i,
                                     [AST.Anchor, parents...])
    token = get(tokens, i, nothing)
    @debug "Got the description" description_node token
    if isnothing(token) || !(token isa Tokens.Token{Tokens.LeftBrace})
        return i, AST.Node(AST.Node[description_node], AST.Anchor(false))
    else
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    location_match = match_norg(AST.LinkLocation, token,
                                [AST.Anchor, parents...], tokens, i)
    @debug "This matches" location_match
    if isclosing(location_match)
        if location_match.consume
            i = nextind(tokens, i)
        end
        return i, AST.Node(AST.Node[description_node], AST.Anchor(false))
    end
    i, location_node = parse_norg(matched(location_match), tokens, i,
                                  [AST.Anchor, parents...])
    i, AST.Node(AST.Node[description_node, location_node], AST.Anchor(true))
end
