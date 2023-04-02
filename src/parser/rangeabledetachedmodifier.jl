strategy_to_kind(::Definition) = K"Definition"
strategy_to_kind(::Footnote) = K"Footnote"
function parse_norg(t::RangeableDetachedModifier, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    parents = [strategy_to_kind(t), parents...]
    children = AST.Node[]
    while !is_eof(tokens[i])
        m = match_norg(parents, tokens, i)
        if isclosing(m)
            if !consume(m)
                i = prevind(tokens, i)
            else
                stop = prevind(tokens, consume_until(K"LineEnding", tokens, i))
                if !isempty(children)
                    child = last(children)
                    children[end] = AST.Node(K"RangeableItem", child.children, AST.start(child), stop)
                end
                i = stop
            end
            break
        elseif matched(m) ∉ KSet"WeakCarryoverTag RangeableItem"
            i = prevind(tokens, i)
            break
        end
        child = if kind(matched(m)) == K"WeakCarryoverTag"
            parse_norg(WeakCarryoverTag(), parents, tokens, i)
        else
            parse_norg(RangeableItem(), parents, tokens, i)
        end
        i = AST.stop(child)
        if !is_eof(tokens[i])
            i = nextind(tokens, i)
        end
        push!(children, child)
    end

    AST.Node(strategy_to_kind(t), children, start, i)
end

function parse_norg(::RangeableItem, parents::Vector{Kind}, tokens::Vector{Token}, i)
    parents = [K"RangeableItem", parents...]
    if AST.is_whitespace(tokens[i])
        i = nextind(tokens, i)
    end
    to_repeat = tokens[i]
    i = nextind(tokens, i)
    token = tokens[i]
    if kind(token) == kind(to_repeat)
        i = nextind(tokens, i)
        i = nextind(tokens, i)
        parse_norg_ranged_rangeable(parents, tokens, i)
    else
        i = nextind(tokens, i)
        parse_norg_unranged_rangeable(parents, tokens, i)
    end
end

function parse_norg_unranged_rangeable(parents, tokens, i)
    title_segment = parse_norg(ParagraphSegment(), parents, tokens, i)
    paragraph = parse_norg(Paragraph(), parents, tokens, nextind(tokens, AST.stop(title_segment)))

    AST.Node(K"RangeableItem", [title_segment, paragraph], i, AST.stop(paragraph))
end

function parse_norg_ranged_rangeable(parents, tokens, i)
    start = i
    title_segment = parse_norg(ParagraphSegment(), parents, tokens, i)
    children = []
    i = nextind(tokens, AST.stop(title_segment))
    token = tokens[i]
    while !is_eof(token)
        m = match_norg(parents, tokens, i)
        if isclosing(m) 
            if consume(m)
                i = consume_until(K"LineEnding", tokens, i)
                i = prevind(tokens, i)
            else
                i = prevind(tokens, i)
            end
            break
        end
        to_parse = matched(m)
        child = if to_parse == K"Verbatim"
            parse_norg(Verbatim(), parents, tokens, i)
        elseif to_parse == K"StandardRangedTag"
            parse_norg(StandardRangedTag(), parents, tokens, i)
        elseif to_parse == K"WeakCarryoverTag"
            parse_norg(WeakCarryoverTag(), parents, tokens, i)
        elseif to_parse == K"StrongCarryoverTag"
            parse_norg(StrongCarryoverTag(), parents, tokens, i)
        elseif to_parse == K"ParagraphSegment"
            parse_norg(ParagraphSegment(), parents, tokens, i)
        elseif to_parse == K"Definition"
            parse_norg(Definition(), parents, tokens, i)
        elseif to_parse == K"Footnote"
            parse_norg(Footnote(), parents, tokens, i)
        else
            parse_norg(Paragraph(), parents, tokens, i)
        end
        push!(children, child)            
        i = nextind(tokens, AST.stop(child))
        token = tokens[i]
        if is_eof(token)
            i = prevind(tokens, i)
            token = tokens[i]
        end
    end
    AST.Node(K"RangeableItem", [title_segment, children...]::Vector{AST.Node}, start, i)
end
