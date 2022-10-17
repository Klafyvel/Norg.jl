function match_norg(::Heading, parents, tokens, i)
    # Special case when parsing the title of a heading
    if K"HeadingTitle" ∈ parents
        return MatchNotFound()
    end
    nestable_parents = filter(is_nestable, parents)
    if length(nestable_parents) > 0
        return MatchClosing(first(nestable_parents), false)
    end
    new_i = i
    heading_level = 0
    while new_i < lastindex(tokens) && kind(get(tokens, new_i, nothing)) == K"*"
        new_i = nextind(tokens, new_i)
        heading_level += 1
    end
    next_token = get(tokens, new_i, nothing)
    if is_whitespace(next_token)
        ancestor_headings = findfirst(x->is_heading(x) && heading_level(x) >= heading_level, parents)
        if !isnothing(ancestor_headings)
            MatchClosing(parents[ancestor_headings], false)
        else
            MatchFound(heading_level(heading_level))
        end
    else
        MatchNotFound()
    end
end

delimitingmodifier(::StrongDelimiter) = K"StrongDelimitingModifier"
delimitingmodifier(::WeakDelimiter) = K"WeakDelimitingModifier"
delimitingmodifier(::HorizontalRule) = K"HorizontalRule"

function match_norg(::T, parents, tokens, i) where {T<:DelimitingModifier}
    next_i = nextind(tokens, i)
    next_next_i = nextind(tokens, next_i)
    next_token = get(tokens, next_i, nothing)
    next_next_token = get(tokens, next_next_i, nothing)
    token = tokens[i]
    if kind(next_token) == kind(token) && kind(next_next_token) == kind(token)
        new_i = nextind(tokens, next_next_i)
        new_token = get(tokens, new_i, nothing)
        is_delimiting = true
        while new_i < lastindex(tokens) && !is_line_ending(new_token)
            if kind(token) != kind(new_token)
                is_delimiting = false
                break
            end
            new_i = nextind(tokens, new_i)
            new_token = get(tokens, new_i, nothing)
        end
        if is_delimiting
            if first(parents) ∈ [K"ParagraphSegment", K"Paragraph", K"NorgDocument"] || is_heading(first(parents))
                MatchFound(delimitingmodifier(T))
            else
                MatchClosing(first(parents), false)
            end
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end

function nestable(::Quote, level)
    if level<=1
        K"Quote1"
    elseif level == 2
        K"Quote2"
    elseif level == 3
        K"Quote3"
    elseif level == 4
        K"Quote4"
    elseif level == 5
        K"Quote5"
    else
        K"Quote6"
    end
end
function nestable(::UnorderedList, level)
    if level<=1
        K"UnorderedList1"
    elseif level == 2
        K"UnorderedList2"
    elseif level == 3
        K"UnorderedList3"
    elseif level == 4
        K"UnorderedList4"
    elseif level == 5
        K"UnorderedList5"
    else
        K"UnorderedList6"
    end
end
function nestable(::OrderedList, level)
    if level<=1
        K"OrderedList1"
    elseif level == 2
        K"OrderedList2"
    elseif level == 3
        K"OrderedList3"
    elseif level == 4
        K"OrderedList4"
    elseif level == 5
        K"OrderedList5"
    else
        K"OrderedList6"
    end
end
function match_norg(t::T, parents, tokens, i) where {T<:Nestable}
    new_i = i
    nest_level = 0
    token = tokens[i]
    while new_i < lastindex(tokens) &&
        kind(get(tokens, new_i, nothing)) == kind(token)
        new_i = nextind(tokens, new_i)
        nest_level += 1
    end
    next_token = get(tokens, new_i, nothing)
    if kind(next_token) == K"Whitespace"
        ancestor_nestable = filter(is_nestable, parents)
        higher_level_ancestor_id = findfirst(x->nest_level(x) >= nest_level, ancestor_nestable)
        if !isnothing(higher_level_ancestor_id)
            MatchClosing(ancestor_nestable[higher_level_ancestor_id], false)
        elseif first(parents) == nestable(t, nest_level)
            @debug "Create nestable item" nest_level
            MatchFound(K"NestableItem")
        elseif any(nestable_level.(ancestor_nestable) .== nest_level)
            MatchClosing(first(parents), false)
        elseif first(parents) ∈ [K"Paragraph", K"ParagraphSegment"]
            @debug "closing parent" first(parents)
            MatchClosing(first(parents), false)
        else
            @debug "create nestable" nest_level
            MatchFound(nestable(t, nest_level))
        end
    else
        MatchNotFound()
    end
end
