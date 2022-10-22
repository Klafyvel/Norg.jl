function parse_norg(::Heading, parents, tokens, i)
    start = i
    token = get(tokens, i, nothing)
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
    end
    heading_level = 0
    # Consume stars to determine heading level
    while i < lastindex(tokens) && kind(token) == K"*"
        i = nextind(tokens, i)
        token = get(tokens, i, nothing)
        heading_level += 1
    end
    heading_kind = AST.heading_level(heading_level)
    @debug "Potential heading level" heading_kind
    if is_whitespace(token)
        title_segment = parse_norg(ParagraphSegment(), [heading_kind, parents...], tokens, nextind(tokens, i))
        i = nextind(tokens, AST.stop(title_segment))
        children = [title_segment]
        m = Match.MatchClosing(heading_kind)
        while i <= lastindex(tokens)
            m = match_norg([heading_kind, parents...], tokens, i)
            @debug "Heading loop" m isclosing(m) tokens[i]
            if isclosing(m)
                break
            end
            to_parse = matched(m)
            if is_heading(to_parse)
                @debug "heading"
                child = parse_norg(Heading(), [heading_kind, parents...], tokens, i)
            elseif to_parse == K"WeakDelimitingModifier"
                @debug "weak"
                start_del = i
                i = consume_until(K"LineEnding", tokens, i)
                push!(children, AST.Node(K"WeakDelimitingModifier", AST.Node[], start_del, i))
                break
            elseif kind(to_parse) == K"StrongDelimitingModifier"
                i = prevind(tokens, i)
                @debug "strong"
                break
            # elseif kind(to_parse) == K"NestableDetachedModifier"
            #     child = parse_norg(to_parse, tokens, i, [t, parents...])
            else
                @debug "paragraph"
                child = parse_norg(Paragraph(), [heading_kind, parents...], tokens, i)
            end
            i = nextind(tokens, AST.stop(child))
            if kind(child) == K"None"
                append!(children, child.children)
            else
                push!(children, child)
            end
        end
        if isclosing(m) && !(matched(m) == heading_kind && consume(m))
            i = prevind(tokens, i)
        end
            
        AST.Node(heading_kind, children, start, i)
    else # if the stars are not followed by a whitespace
        # This should never happen if matching works correctly
            # parse_norg(Paragraph(), parents, tokens, i)
        error("Matching for headings has a bug. Please report the issue.")
    end
end
