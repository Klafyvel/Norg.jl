function parse_norg(t::Type{AST.Heading{T}}, tokens, i, parents) where {T}
    token = get(tokens, i, nothing)
    if token isa Token{Tokens.Whitespace} # consume leading whitespace
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    heading_level = 0
    # Consume stars to determine heading level
    while i < lastindex(tokens) && token isa Token{Tokens.Star}
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        heading_level += 1
    end
    if token isa Token{Tokens.Whitespace}
        i, title_segment = parse_norg(AST.ParagraphSegment, tokens,
                                      nextind(tokens, i),
                                      [AST.Heading, parents...])
        children = AST.Node[]
        m = Match.MatchClosing{AST.Heading{T}}()
        while i < lastindex(tokens)
            m = match_norg([t, parents...], tokens, i)
            if isclosing(m)
                break
            end
            to_parse = matched(m)
            if to_parse <: AST.Heading
                i, child = parse_norg(to_parse, tokens, i, [t, parents...])
            elseif to_parse <: AST.WeakDelimitingModifier
                i = consume_until(Tokens.LineEnding, tokens, i)
                push!(children,
                      AST.Node(AST.Node[], AST.WeakDelimitingModifier()))
                break
            elseif to_parse <: AST.StrongDelimitingModifier
                break
            elseif to_parse <: AST.NestableDetachedModifier
                i, child = parse_norg(to_parse, tokens, i, [t, parents...])
            else
                i, child = parse_norg(AST.Paragraph, tokens, i, [t, parents...])
            end
            if child isa Vector
                append!(children, child)
            else
                push!(children, child)
            end
        end
        i, AST.Node(children, t(title_segment))
    else # if the stars are not followed by a whitespace, toss them aside and fall back on a paragraph.
        parse_norg(AST.Paragraph, tokens, i, parents)
    end
end
