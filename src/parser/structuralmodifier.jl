function parse_norg(::Heading, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    token = tokens[i]
    if is_whitespace(token) # consume leading whitespace
        i = nextind(tokens, i)
        token = tokens[i]
    end
    heading_level = 0
    # Consume stars to determine heading level
    while !is_eof(tokens[i]) && kind(token) == K"*"
        i = nextind(tokens, i)
        token = tokens[i]
        heading_level += 1
    end
    heading_kind = AST.heading_level(heading_level)
    if is_whitespace(token)
        i = nextind(tokens, i)
        m = match_norg([heading_kind, parents...], tokens, i)
        children = []
        if is_detached_modifier_extension(matched(m))
            extension = parse_norg(DetachedModifierExtension(), parents, tokens, i)
            push!(children, extension)
            i = nextind(tokens, extension.stop)
            if kind(tokens[i]) == K"Whitespace"
                i = consume_until(K"Whitespace", tokens, i)
            end
        end
        title_segment = parse_norg(ParagraphSegment(), [heading_kind, parents...], tokens, i)
        push!(children, title_segment)
        i = nextind(tokens, AST.stop(title_segment))
        while !is_eof(tokens[i])
            m = match_norg([heading_kind, parents...], tokens, i)
            @debug "heading loop" 
            if isclosing(m)
                break
            end
            to_parse = matched(m)
            if is_heading(to_parse)
                child = parse_norg(Heading(), [heading_kind, parents...], tokens, i)
            elseif to_parse == K"WeakDelimitingModifier"
                start_del = i
                i = consume_until(K"LineEnding", tokens, i)
                push!(children, AST.Node(K"WeakDelimitingModifier", AST.Node[], start_del, i))
                break
            elseif kind(to_parse) == K"StrongDelimitingModifier"
                i = prevind(tokens, i)
                break
            elseif kind(to_parse) == K"HorizontalRule"
                start_hr = i
                stop_hr = consume_until(K"LineEnding", tokens, i)
                child = AST.Node(to_parse, AST.Node[], start_hr, stop_hr)
            elseif is_quote(to_parse)
                child = parse_norg(Quote(), [heading_kind, parents...], tokens, i)
            elseif is_unordered_list(to_parse)
                child = parse_norg(UnorderedList(), [heading_kind, parents...], tokens, i)
            elseif is_ordered_list(to_parse)
                child = parse_norg(OrderedList(), [heading_kind, parents...], tokens, i)
            elseif kind(to_parse) == K"Verbatim"
                child = parse_norg(Verbatim(), [heading_kind, parents...], tokens, i)
            elseif to_parse == K"WeakCarryoverTag"
                child = parse_norg(WeakCarryoverTag(), parents, tokens, i)
            elseif to_parse == K"Definition"
                child = parse_norg(Definition(), parents, tokens, i)
            elseif to_parse == K"Footnote"
                child = parse_norg(Footnote(), parents, tokens, i)
            else
                child = parse_norg(Paragraph(), [heading_kind, parents...], tokens, i)
            end
            i = AST.stop(child)
            if !is_eof(tokens[i])
                i = nextind(tokens, AST.stop(child))
            end
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
