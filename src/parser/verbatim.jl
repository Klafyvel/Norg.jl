function parse_norg(::Verbatim, parents, tokens, i)
    start = i
    @debug "hey, parsing verbatim"
    token = get(tokens, i, nothing)
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "this is tagname" token
    children = [AST.Node(K"VerbatimTag", AST.Node[], i, i)]
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "after tagname we have" token
    if kind(token) == K"."
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        @debug "wow, this was a dot, now we have" token
        if kind(token) == K"Word"
            push!(children, AST.Node(K"VerbatimTag", AST.Node[], i, i))
            i = nextind(tokens, i)
            token = get(tokens, i, nothing)
        end
    end
    if kind(token) == K"Whitespace"
        @debug "consuming whitespace" token
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    start_current = i
    while i <= lastindex(tokens) && kind(token) != K"LineEnding"
        @debug "hallo, it's parameter parsing loop" token
        if is_whitespace(token)
            push!(children, AST.Node(K"VerbatimParameter", AST.Node[], start_current, prevind(tokens, i)))
            i = nextind(tokens, i)
            start_current = i
            token = get(tokens, i, nothing)
            continue
        end
        if kind(token) == K"\\"
            i = nextind(tokens, i)
            token = get(tokens, i, nothing)
        end
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if kind(token) == K"LineEnding"
        if start_current < i
            push!(children, AST.Node(K"VerbatimParameter", AST.Node[], start_current, prevind(tokens, i)))
        end
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    start_content = i
    stop_content = i
    while i <= lastindex(tokens)
        if kind(token) == K"@" #maybe it's the end
            prev_i = prevind(tokens, i)
            prev_token = get(tokens, prev_i, nothing)
            prev_prev_i = prevind(tokens, prev_i)
            prev_prev_token = get(tokens, prev_prev_i, nothing)
            @debug "Got a @ sign !" token prev_token prev_prev_token
            if kind(prev_token) == K"LineEnding" || (kind(prev_token) == K"Whitespace" && kind(prev_prev_token) == K"LineEnding")
                next_i = nextind(tokens, i)
                next_token = get(tokens, next_i, nothing)
                next_next_i = nextind(tokens, next_i)
                next_next_token = get(tokens, next_next_i, nothing)
                @debug "It has the right prev tokens !" next_token next_next_token
                if kind(next_token) == K"Word" && kind(next_next_token) == K"LineEnding" && value(next_token) == "end"
                    stop_content = prev_i
                    i = next_next_i
                    @debug "And the magic word !" value(next_token)
                    break
                end
            end
        end
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    push!(children, AST.Node(K"VerbatimBody", AST.Node[], start_content, stop_content))
    AST.Node(K"Verbatim", children, start, i)
end
