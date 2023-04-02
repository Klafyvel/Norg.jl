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
attachedmodifier(::FreeFormBold) = K"FreeFormBold"
attachedmodifier(::FreeFormItalic) = K"FreeFormItalic"
attachedmodifier(::FreeFormUnderline) = K"FreeFormUnderline"
attachedmodifier(::FreeFormStrikethrough) = K"FreeFormStrikethrough"
attachedmodifier(::FreeFormSpoiler) = K"FreeFormSpoiler"
attachedmodifier(::FreeFormSuperscript) = K"FreeFormSuperscript"
attachedmodifier(::FreeFormSubscript) = K"FreeFormSubscript"
attachedmodifier(::FreeFormInlineCode) = K"FreeFormInlineCode"
attachedmodifier(::FreeFormNullModifier) = K"FreeFormNullModifier"
attachedmodifier(::FreeFormInlineMath) = K"FreeFormInlineMath"
attachedmodifier(::FreeFormVariable) = K"FreeFormVariable"

freeformattachedmodifier(::Bold) = K"FreeFormBold"
freeformattachedmodifier(::Italic) = K"FreeFormItalic"
freeformattachedmodifier(::Underline) = K"FreeFormUnderline"
freeformattachedmodifier(::Strikethrough) = K"FreeFormStrikethrough"
freeformattachedmodifier(::Spoiler) = K"FreeFormSpoiler"
freeformattachedmodifier(::Superscript) = K"FreeFormSuperscript"
freeformattachedmodifier(::Subscript) = K"FreeFormSubscript"
freeformattachedmodifier(::InlineCode) = K"FreeFormInlineCode"
freeformattachedmodifier(::NullModifier) = K"FreeFormNullModifier"
freeformattachedmodifier(::InlineMath) = K"FreeFormInlineMath"
freeformattachedmodifier(::Variable) = K"FreeFormVariable"
freeformattachedmodifier(t::T) where {T <: FreeFormAttachedModifier} = attachedmodifier(t)

function match_norg(t::T, parents, tokens, i) where {T<:AttachedModifierStrategy}
    if K"LinkLocation" ∈ parents
        return MatchNotFound()
    end
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    prev_i = prevind(tokens, i)
    last_token = tokens[prev_i]
    # if opening modifier is found
    if (is_sof(last_token) || is_punctuation(last_token) || is_whitespace(last_token)) && (!is_eof(next_token) && !is_whitespace(next_token))
        if kind(next_token) == K"|"
            MatchFound(freeformattachedmodifier(t))
        else
            MatchFound(attachedmodifier(t))
        end
    # Link modifier
    elseif kind(last_token) == K":" && (!is_eof(next_token) && !is_whitespace(next_token))
        prev_prev_i = prevind(tokens, prev_i)
        if prev_prev_i >= firstindex(tokens) && (is_sof(tokens[prev_prev_i]) || is_punctuation(tokens[prev_prev_i]) || is_whitespace(tokens[prev_prev_i]))
            MatchFound(attachedmodifier(t))
        else
            MatchNotFound()
        end
    # Closing modifier
    elseif attachedmodifier(t) ∈ parents && !is_whitespace(last_token) && (is_eof(next_token) || is_whitespace(next_token) || is_punctuation(next_token))
        MatchClosing(attachedmodifier(t), first(parents)==attachedmodifier(t))
    else
        MatchNotFound()
    end
end

function match_norg(t::T, parents, tokens, i) where {T <: Union{VerbatimAttachedModifierStrategy, FreeFormAttachedModifier}}
    if K"LinkLocation" ∈ parents
        return MatchNotFound()
    end
    next_i = nextind(tokens, i)
    next_token = tokens[next_i]
    prev_i = prevind(tokens, i)
    last_token = tokens[prev_i]
    token = tokens[i]
    # Opening modifier
    if attachedmodifier(t) ∉ parents && (is_sof(last_token) || is_punctuation(last_token) || is_whitespace(last_token)) && (!is_eof(next_token) && !is_whitespace(next_token))
        if kind(next_token) == K"|"
            # Edge case: we want to be able to write `|` (verbatim attached
            # modifiers have higher precedence than free-form attached modifiers)
            i = nextind(tokens, next_i)
            token = tokens[i]
            next_i = nextind(tokens, i)
            next_token = tokens[next_i]
            if kind(token) == K"`" && (is_punctuation(next_token) || is_whitespace(next_token) || is_eof(next_token))
                MatchFound(attachedmodifier(t))
            else
                MatchFound(freeformattachedmodifier(t))
            end
        elseif kind(token) == K"|"
            MatchNotFound()
        else
            MatchFound(attachedmodifier(t))
        end
    # Closing modifier
    elseif attachedmodifier(t) ∈ parents && t isa FreeFormAttachedModifier
        MatchClosing(attachedmodifier(t), first(parents)==attachedmodifier(t))
    elseif attachedmodifier(t) ∈ parents && !is_whitespace(last_token) && (is_eof(next_token) || is_whitespace(next_token) || is_punctuation(next_token))
        MatchClosing(attachedmodifier(t), first(parents) == attachedmodifier(t))
    # Link modifier
    elseif !(t isa FreeFormAttachedModifier) && kind(last_token) == K":" && (!is_eof(next_token) && !is_whitespace(next_token))
        prev_prev_i = prevind(tokens, prev_i)
        if prev_prev_i >= firstindex(tokens) && (is_sof(tokens[prev_prev_i]) || is_punctuation(tokens[prev_prev_i]) || is_whitespace(tokens[prev_prev_i]))
            MatchFound(attachedmodifier(t))
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end
