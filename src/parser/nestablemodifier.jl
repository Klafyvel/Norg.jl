function parse_norg(t::Type{<:AST.NestableDetachedModifier{level}}, tokens, i, parents) where {level}
    token = get(tokens, i, nothing)

    children = AST.Node[]
    while i < lastindex(tokens)
        token = get(tokens, i, nothing)
        m = match_norg(token, [t, parents...], tokens, i)
        if isclosing(m)
            if m.consume
                i = nextind(tokens, i)
            end
            break
        elseif iscontinue(m)
            if token isa Token{Tokens.Whitespace} # consume leading whitespace
                i = nextind(tokens, i)
                token = get(tokens, i, nothing)
            end
            # Consume tokens creating the delimiter
            i = consume_until(Tokens.Whitespace, tokens, i)
            to_parse = AST.Paragraph 
        else
            to_parse = matched(m)
        end
        i, child = parse_norg(to_parse, tokens, i, [t, parents...])
        push!(children, child)
    end
    i, AST.Node(children, t())
end


