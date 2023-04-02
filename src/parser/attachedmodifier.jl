consumepre(::T) where {T<:AttachedModifierStrategy} = 1
consumepre(::FreeFormBold) = 2
consumepre(::FreeFormItalic) = 2
consumepre(::FreeFormUnderline) = 2
consumepre(::FreeFormStrikethrough) = 2
consumepre(::FreeFormSpoiler) = 2
consumepre(::FreeFormSuperscript) = 2
consumepre(::FreeFormSubscript) = 2
consumepre(::FreeFormNullModifier) = 2
consumepre(::FreeFormInlineCode) = 2
consumepre(::FreeFormInlineMath) = 2
consumepre(::FreeFormVariable) = 2
consumepost(::T) where {T<:AttachedModifierStrategy} = 1
consumepost(::FreeFormBold) = 2
consumepost(::FreeFormItalic) = 2
consumepost(::FreeFormUnderline) = 2
consumepost(::FreeFormStrikethrough) = 2
consumepost(::FreeFormSpoiler) = 2
consumepost(::FreeFormSuperscript) = 2
consumepost(::FreeFormSubscript) = 2
consumepost(::FreeFormNullModifier) = 2
consumepost(::FreeFormInlineCode) = 2
consumepost(::FreeFormInlineMath) = 2
consumepost(::FreeFormVariable) = 2

function parse_norg(t::T, parents::Vector{Kind}, tokens::Vector{Token}, i) where {T<:AttachedModifierStrategy}
    start = i
    children = AST.Node[]
    for _ in 1:consumepre(t)
        i = nextind(tokens, i)
    end
    node_kind = Match.attachedmodifier(t)
    m = Match.MatchClosing(node_kind)
    while !is_eof(tokens[i])
        m = match_norg([node_kind, parents...], tokens, i)
        if isclosing(m)
            if consume(m) && consumepost(t) >= 2
                for _ in 1:(consumepost(t)-1)
                    i = nextind(tokens, i)
                end
            end
            break
        end
        segment = parse_norg(ParagraphSegment(), [node_kind, parents...], tokens, i)
        i = nextind(tokens, AST.stop(segment))
        if kind(segment) == K"None"
            append!(children, segment.children)
        else
            push!(children, segment)
        end
    end
    if is_eof(tokens[i]) ||
        (isclosing(m) && matched(m) == K"None") || # Special case for inline code precedence.
        (isclosing(m) && matched(m) != node_kind && matched(m) ∈ parents) # we've been tricked in thincking we were in a modifier.
        new_children = [parse_norg(Word(), parents, tokens, start), first(children).children...]
        children[1] = AST.Node(K"ParagraphSegment", new_children, start, AST.stop(first(children)))
        i = prevind(tokens, i)
        node_kind = K"None"
    elseif isempty(children) # Empty attached modifiers are forbiddens
        children = [parse_norg(Word(), parents, tokens, start), parse_norg(Word(), parents, tokens, i)]
        node_kind = K"None"
    elseif isclosing(m) && !consume(m)
        i = prevind(tokens, i)
    elseif isclosing(m) && kind(tokens[nextind(tokens, i)]) == K":"
        i = nextind(tokens, i)
    end
    AST.Node(node_kind, children, start, i)
end
