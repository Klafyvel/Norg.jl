function parse_norg(::Type{AST.Verbatim}, tokens, i, parents)
    @debug "hey, parsing verbatim"
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "this is tagname" token
    tagname = value(token)
    i = nextind(tokens, i)
    token = get(tokens, i, nothing)
    @debug "after tagname we have" token
    subtag = nothing
    if token isa Token{Tokens.Dot}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        @debug "wow, this was a dot, now we have" token
        if token isa Token{Tokens.Word}
            subtag = value(token)
            i = nextind(tokens, i)
            token = get(tokens, i, nothing)
        end
    end
    if token isa Token{Tokens.Whitespace}
        @debug "consuming whitespace" token
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    parameters = String[]
    current = String[]
    while i <= lastindex(tokens) && !isa(token, Token{Tokens.LineEnding})
        @debug "hallo, it's parameter parsing loop" token
        if token isa Token{Tokens.Whitespace}
            push!(parameters, join(current))
            current = String[]
            i = nextind(tokens, i)
            token = get(tokens, i, nothing)
            continue
        end
        if token isa Token{Tokens.BackSlash}
            i = nextind(tokens, i)
            token = get(tokens, i, nothing)
        end
        push!(current, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    if !isempty(current)
        push!(parameters, join(current))
    end
    if token isa Token{Tokens.LineEnding}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    child_content = String[]
    while i <= lastindex(tokens)
        if token isa Token{Tokens.CommercialAtSign} #maybe it's the end
            prev_i = prevind(tokens, i)
            prev_token = get(tokens, prev_i, nothing)
            prev_prev_i = prevind(tokens, i)
            prev_prev_token = get(tokens, prev_prev_i, nothing)
            if prev_token isa Token{Tokens.LineEnding} ||
               (prev_token isa Token{Tokens.Whitespace} &&
                prev_prev_token isa Token{Tokens.LineEnding})
                next_i = nextind(tokens, i)
                next_token = get(tokens, next_i, nothing)
                next_next_i = nextind(tokens, next_i)
                next_next_token = get(tokens, next_next_i, nothing)
                if next_token isa Token{Tokens.Word} &&
                   next_next_token isa Token{Tokens.LineEnding} &&
                   value(next_token) == "end"
                    i = next_next_i
                    break
                end
            end
        end
        push!(child_content, value(token))
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    i,
    AST.Node(AST.Node[AST.Node(AST.VerbatimBody(join(child_content)))],
             AST.Verbatim(tagname, subtag, parameters))
end
