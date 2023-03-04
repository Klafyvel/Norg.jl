function match_norg(::Heading, parents, tokens, i)
    # Special case when parsing the title of a heading
    if K"HeadingTitle" ∈ parents
        return MatchNotFound()
    end
    relevant_parents = if K"StandardRangedTag" ∈ parents
        k = findfirst(parents .== Ref(K"StandardRangedTag"))::Int
        parents[1:k]
    else
        parents
    end
    nestable_parents = filter(is_nestable, relevant_parents)
    if length(nestable_parents) > 0
        return MatchClosing(first(nestable_parents), false)
    end
    new_i = i
    level = 0
    while new_i < lastindex(tokens) && kind(tokens[new_i]) == K"*"
        new_i = nextind(tokens, new_i)
        level += 1
    end
    next_token = tokens[new_i]
    if kind(next_token) == K"Whitespace"
        # If we are in a standard ranged tag, the relevant parents are those
        # within the tag.
        ancestor_headings = filter(is_heading, relevant_parents)
        higher_level_ancestor_heading = findfirst(x -> heading_level(x) >= level, ancestor_headings)
        @debug "Closing heading ?" relevant_parents higher_level_ancestor_heading
        if !isnothing(higher_level_ancestor_heading)
            MatchClosing(ancestor_headings[higher_level_ancestor_heading], false)
        elseif first(relevant_parents) ∈ [K"ParagraphSegment", K"Paragraph"]
            MatchClosing(first(relevant_parents), false)
        else
            MatchFound(heading_level(level))
        end
    else
        MatchNotFound()
    end
end

delimitingmodifier(::StrongDelimiter) = K"StrongDelimitingModifier"
delimitingmodifier(::WeakDelimiter) = K"WeakDelimitingModifier"
delimitingmodifier(::HorizontalRule) = K"HorizontalRule"

function match_norg(t::T, parents, tokens, i) where {T<:DelimitingModifier}
    next_i = nextind(tokens, i)
    next_next_i = nextind(tokens, next_i)
    next_token = tokens[next_i]
    if is_eof(next_token)
        return MatchNotFound()
    end
    next_next_token = tokens[next_next_i]
    token = tokens[i]
    if kind(next_token) == kind(token) && kind(next_next_token) == kind(token)
        new_i = nextind(tokens, next_next_i)
        new_token = tokens[new_i]
        is_delimiting = true
        while new_i < lastindex(tokens) && !is_line_ending(new_token)
            if kind(token) != kind(new_token)
                is_delimiting = false
                break
            end
            new_i = nextind(tokens, new_i)
            new_token = tokens[new_i]
        end
        if is_delimiting
            @debug "Found a delimiter" delimitingmodifier(t) parents
            if first(parents) ∈ KSet"NorgDocument IndentSegment StandardRangedTagBody" || is_heading(first(parents))
                MatchFound(delimitingmodifier(t))
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
    level = 0
    token = tokens[i]
    while new_i < lastindex(tokens) && kind(tokens[new_i]) == kind(token)
        new_i = nextind(tokens, new_i)
        level += 1
    end
    next_token = tokens[new_i]
    if kind(next_token) == K"Whitespace"
        ancestor_nestable = filter(is_nestable, parents)
        higher_level_ancestor_id = findfirst(x->nestable_level(x) > level, ancestor_nestable)
        if !isnothing(higher_level_ancestor_id)
            MatchClosing(ancestor_nestable[higher_level_ancestor_id], false)
        elseif first(parents) == nestable(t, level)
            MatchFound(K"NestableItem")
        elseif any(nestable_level.(ancestor_nestable) .== level)
            MatchClosing(first(parents), false)
        elseif first(parents) ∈ [K"Paragraph", K"ParagraphSegment"]
            @debug "Chérie ça va couper." parents tokens[i]
            MatchClosing(first(parents), false)
        else
            MatchFound(nestable(t, level))
        end
    else
        MatchNotFound()
    end
end
