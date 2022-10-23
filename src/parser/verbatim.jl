function parse_norg(::Verbatim, parents, tokens, i)
    start = i
    token = tokens[i]
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = tokens[i]
    end
    i = nextind(tokens, i)
    token = tokens[i]
    children = [AST.Node(K"VerbatimTag", AST.Node[], i, i)]
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == K"."
        i = nextind(tokens, i)
        token = tokens[i]
        if kind(token) == K"Word"
            push!(children, AST.Node(K"VerbatimTag", AST.Node[], i, i))
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    if kind(token) == K"Whitespace"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_current = i
    while !is_eof(tokens[i]) && kind(token) != K"LineEnding"
        if is_whitespace(token)
            push!(children, AST.Node(K"VerbatimParameter", AST.Node[], start_current, prevind(tokens, i)))
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
            push!(children, AST.Node(K"VerbatimParameter", AST.Node[], start_current, prevind(tokens, i)))
        end
        i = nextind(tokens, i)
        token = tokens[i]
    end
    start_content = i
    stop_content = i
    while !is_eof(tokens[i])
        if kind(token) == K"@" #maybe it's the end
            prev_i = prevind(tokens, i)
            prev_token = get(tokens, prev_i, nothing)
            prev_prev_i = prevind(tokens, prev_i)
            prev_prev_token = get(tokens, prev_prev_i, nothing)
            if kind(prev_token) == K"LineEnding" || (kind(prev_token) == K"Whitespace" && kind(prev_prev_token) == K"LineEnding")
                next_i = nextind(tokens, i)
                next_token = get(tokens, next_i, nothing)
                next_next_i = nextind(tokens, next_i)
                next_next_token = get(tokens, next_next_i, nothing)
                if kind(next_token) == K"Word" && kind(next_next_token) == K"LineEnding" && value(next_token) == "end"
                    stop_content = prev_i
                    i = next_next_i
                    break
                end
            end
        end
        i = nextind(tokens, i)
        token = tokens[i]
    end
    push!(children, AST.Node(K"VerbatimBody", AST.Node[], start_content, stop_content))
    AST.Node(K"Verbatim", children, start, i)
end
