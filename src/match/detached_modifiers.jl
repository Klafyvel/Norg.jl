function match_norg(::Type{AST.Heading}, token, parents, tokens, i)
    new_i = i
    heading_level = 0
    while new_i < lastindex(tokens) &&
        get(tokens, new_i, nothing) isa Token{Tokens.Star}
        new_i = nextind(tokens, new_i)
        heading_level += 1
    end
    next_token = get(tokens, new_i, nothing)
    if next_token isa Token{Tokens.Whitespace}
        previous_heading_level = AST.headinglevel.(filter(x -> x <: AST.Heading,
                                                          parents))
        if any(previous_heading_level .>= heading_level)
            closing_level = first(previous_heading_level[previous_heading_level .>= heading_level])
            MatchClosing{AST.Heading{closing_level}}()
        else
            MatchFound{AST.Heading{heading_level}}()
        end
    else
        MatchNotFound()
    end
end

delimitingmodifier(::Type{Tokens.EqualSign}) = AST.StrongDelimitingModifier
delimitingmodifier(::Type{Tokens.Minus}) = AST.WeakDelimitingModifier
delimitingmodifier(::Type{Tokens.Underscore}) = AST.HorizontalRule

function match_norg(::Type{AST.DelimitingModifier}, ::Token{T}, parents, tokens, i) where {T}
    next_i = nextind(tokens, i)
    next_next_i = nextind(tokens, next_i)
    next_token = get(tokens, next_i, nothing)
    next_next_token = get(tokens, next_next_i, nothing)
    if next_token isa Token{T} && next_next_token isa Token{T}
        new_i = nextind(tokens, next_next_i)
        token = get(tokens, new_i, nothing)
        is_delimiting = true
        while new_i < lastindex(tokens) && !(token isa Token{Tokens.LineEnding})
            if !(token isa Token{T})
                is_delimiting = false
                break
            end
            new_i = nextind(tokens, next_next_i)
            token = get(tokens, new_i, nothing)
        end
        if is_delimiting
            MatchFound{delimitingmodifier(T)}()
        else
            MatchNotFound()
        end
    else
        MatchNotFound()
    end
end

