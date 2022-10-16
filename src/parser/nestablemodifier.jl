function parse_norg(t::Type{<:AST.NestableDetachedModifier{level}}, tokens, i,
                    parents) where {level}
    children = AST.Node[]
    while i <= lastindex(tokens)
        m = match_norg([t, parents...], tokens, i)
        @debug "nestable detached modifier loop" tokens[i] m
        if isclosing(m)
            if m.consume
                i = nextind(tokens, i)
            end
            break
        end
        i, child = parse_norg(matched(m), tokens, i, [t, parents...])
        push!(children, child)
    end
    i, AST.Node(children, t())
end

function parse_norg(t::Type{AST.NestableItem}, tokens, i, parents)
    @debug "nestable item"
    token = get(tokens, i, nothing)
    children = AST.Node[]
    if token isa Token{Tokens.Whitespace} # consume leading whitespace
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    # Consume tokens creating the delimiter
    i = consume_until(Tokens.Whitespace, tokens, i)
    @debug "nestable" i <= lastindex(tokens)
    while i <= lastindex(tokens)
        m = match_norg([t, parents...], tokens, i)
        @debug "nestable item loop" tokens[i] m
        if isclosing(m)
            if m.consume
                i = nextind(tokens, i)
            end
            break
        end
        to_parse = matched(m)
        if !(to_parse <: AST.FirstClassNode)
            to_parse = AST.Paragraph            
        end
        i, child = parse_norg(to_parse, tokens, i, [t, parents...])
        push!(children, child)
    end
    i, AST.Node(children, t())
end
