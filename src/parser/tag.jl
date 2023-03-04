function parse_tag_header(parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    token = tokens[i]
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = tokens[i]
    end
    tagnamestart = nextind(tokens, i)
    i = consume_until(KSet"LineEnding Whitespace .", tokens, tagnamestart) - 2
    children = [AST.Node(K"TagName", AST.Node[], tagnamestart, i)]
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"."
        i = nextind(tokens, i)
        subtagnamestart = i
        token = tokens[i]
        if kind(token) == K"Word"
            i = consume_until(KSet"LineEnding Whitespace", tokens, i) - 2
            push!(children, AST.Node(K"TagName", AST.Node[], subtagnamestart, i))
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    @debug "coucou" token
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_current = i
    while !is_eof(tokens[i]) && kind(token) != K"LineEnding"
        if is_whitespace(token)
            push!(children, AST.Node(K"TagParameter", AST.Node[], start_current, prevind(tokens, i)))
            i = nextind(tokens, i)
            start_current = i
            token = tokens[i]
            continue
        end
        if kind(token) == K"\\"
            i = nextind(tokens, i)
            token = tokens[i]
        end
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) == K"LineEnding"
        if start_current < i
            push!(children, AST.Node(K"TagParameter", AST.Node[], start_current, prevind(tokens, i)))
        end
        i = nextind(tokens, i)
        token = tokens[i]
    end
    children, i
end

tag(::Verbatim) = K"Verbatim"
tag(::StandardRangedTag) = K"StandardRangedTag"
body(::Verbatim) = K"VerbatimBody"
body(::StandardRangedTag) = K"StandardRangedTagBody"

function parse_norg(t::T, parents::Vector{Kind}, tokens::Vector{Token}, i) where {T <: Tag}
    start = i
    children, i = parse_tag_header(parents, tokens, i)
    token = tokens[i]
    start_content = i
    stop_content = i
    p = [body(t), tag(t), parents...]
    body_children = AST.Node[]
    @debug "tag parsing" start start_content tokens[i]
    while !is_eof(tokens[i])
        m = match_norg(p, tokens, i)
        @debug "tag loop" m tokens[i]
        if isclosing(m)
            @debug "Closing tag" m tokens[i]
            stop_content = prevind(tokens, i)
            if kind(tokens[i]) == K"LineEnding"
                i = nextind(tokens, i)
            end
            @debug "after advancing" tokens[i]
            i = consume_until(K"LineEnding", tokens, i)
            if tokens[i] != K"EndOfFile"
                i = prevind(tokens, i)
            end
            break
        elseif iscontinue(m)
            i = nextind(tokens, i)
            continue
        end
        c = parse_norg_toplevel_one_step(p, tokens, i)
        push!(body_children, c)
        i = nextind(tokens, AST.stop(c))
    end
    push!(children, AST.Node(body(t), body_children, start_content, stop_content))
    @debug "Closed tag" i tokens[i] parents
    AST.Node(tag(t), children, start, i)
end

function parse_norg(::WeakCarryoverTag, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    children, i = parse_tag_header(parents, tokens, i)
    @debug "Weak carryover tag here" tokens[i]
    content = parse_norg_toplevel_one_step([parents...], tokens, i)
    @debug "hey there" content parents
    if kind(content) == K"Paragraph" || is_nestable(kind(content))
        content_children = content.children
        first_segment = first(content_children)
        content_children[1] = AST.Node(K"WeakCarryoverTag", [children..., first_segment], start, AST.stop(first_segment))
        AST.Node(kind(content), content_children, AST.start(content), AST.stop(content))
    else
        AST.Node(K"WeakCarryoverTag", [children..., content], start, AST.stop(content))
    end
end

function parse_norg(::StrongCarryoverTag, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    children, i = parse_tag_header(parents, tokens, i)
    @debug "Strong carryover tag here" tokens[i]
    m = match_norg(parents, tokens, i)
    if isclosing(m)
        AST.Node(K"StrongCarryoverTag", children, start, prevind(tokens, i))
    else
        content = parse_norg_toplevel_one_step([parents...], tokens, i)
        @debug "hey there" content parents
        AST.Node(K"StrongCarryoverTag", [children..., content], start, AST.stop(content))
    end
end
