attachedmodifier(::Bold) = K"Bold"
attachedmodifier(::Italic) = K"Italic"
attachedmodifier(::Underline) = K"Underline"
attachedmodifier(::Strikethrough) = K"Strikethrough"
attachedmodifier(::Spoiler) = K"Spoiler"
attachedmodifier(::Superscript) = K"Superscript"
attachedmodifier(::Subscript) = K"Subscript"
attachedmodifier(::InlineCode) = K"InlineCode"
attachedmodifier(::NullModifier) = K"NullModifier"
attachedmodifier(::InlineMath) = K"InlineMath"
attachedmodifier(::Variable) = K"Variable"

function match_norg(t::T, parents, tokens, i) where {T<:AttachedModifierStrategy}
    if K"LinkLocation" ∈ parents
        return MatchNotFound()
    end
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    prev_i = prevind(tokens, i)
    last_token = tokens[prev_i]
    if (is_sof(last_token) || is_punctuation(last_token) || is_whitespace(last_token)) && (!is_eof(next_token) && !is_whitespace(next_token))
        MatchFound(attachedmodifier(t))
    elseif kind(last_token) == K":" && (!is_eof(next_token) && !is_whitespace(next_token))
        prev_prev_i = prevind(tokens, prev_i)
        if prev_prev_i >= firstindex(tokens) && (is_sof(tokens[prev_prev_i]) || is_punctuation(tokens[prev_prev_i]) || is_whitespace(tokens[prev_prev_i]))
            MatchFound(attachedmodifier(t))
        else
            MatchNotFound()
        end
    elseif attachedmodifier(t) ∈ parents && !is_whitespace(last_token) && (is_eof(next_token) || is_whitespace(next_token) || is_punctuation(next_token))
        MatchClosing(attachedmodifier(t), first(parents)==attachedmodifier(t))
    else
        MatchNotFound()
    end
end

function match_norg(t::T, parents, tokens, i) where {T <: VerbatimAttachedModifierStrategy}
    if K"LinkLocation" ∈ parents
        return MatchNotFound()
    end
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    prev_i = prevind(tokens, i)
    last_token = tokens[prev_i]
    if attachedmodifier(t) ∉ parents && (is_sof(last_token) || is_punctuation(last_token) || is_whitespace(last_token)) && (!is_eof(next_token) && !is_whitespace(next_token))
        MatchFound(attachedmodifier(t))
    elseif attachedmodifier(t) ∈ parents && !is_whitespace(last_token) && (is_eof(next_token) || is_whitespace(next_token) || is_punctuation(next_token))
        MatchClosing(attachedmodifier(t), first(parents) == attachedmodifier(t))
    else
        MatchNotFound()
    end
end
