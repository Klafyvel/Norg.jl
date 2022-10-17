tokentype(::ParagraphSegment) = K"LineEnding"
tokentype(::Bold) = K"*"
tokentype(::Italic) = K"/"
tokentype(::Underline) = K"_"
tokentype(::Strikethrough) = K"-"
tokentype(::Spoiler) = K"!"
tokentype(::Superscript) = K"^"
tokentype(::Subscript) = K","
tokentype(::InlineCode) = K"`"

attachedmodifier(::Bold) = K"Bold"
attachedmodifier(::Italic) = K"Italic"
attachedmodifier(::Underline) = K"Underline"
attachedmodifier(::Strikethrough) = K"Strikethrough"
attachedmodifier(::Spoiler) = K"Spoiler"
attachedmodifier(::Superscript) = K"Superscript"
attachedmodifier(::Subscript) = K"Subscript"
attachedmodifier(::InlineCode) = K"InlineCode"

function match_norg(t::T, parents, tokens, i) where {T<:AttachedModifier}
    if K"LinkLocation" ∈ parents
        return MatchNotFound()
    end
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if (isnothing(last_token) || is_punctuation(last_token) || is_whitespace(last_token)) && !is_whitespace(next_token) 
        MatchFound(attachedmodifier(t))
    elseif attachedmodifier(t) ∈ parents && (!is_whitespace(last_token) || isnothing(last_token)) && (isnothing(next_token) || is_whitespace(next_token) || is_punctuation(next_token))
        MatchClosing(attachedmodifier(t))
    else
        MatchNotFound()
    end
end
