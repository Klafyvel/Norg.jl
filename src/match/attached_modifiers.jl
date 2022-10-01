tokentype(::Type{AST.ParagraphSegment}) = Tokens.LineEnding
tokentype(::Type{AST.Bold}) = Tokens.Star
tokentype(::Type{AST.Italic}) = Tokens.Slash
tokentype(::Type{AST.Underline}) = Tokens.Underscore
tokentype(::Type{AST.Strikethrough}) = Tokens.Minus
tokentype(::Type{AST.Spoiler}) = Tokens.ExclamationMark
tokentype(::Type{AST.Superscript}) = Tokens.Circumflex
tokentype(::Type{AST.Subscript}) = Tokens.Comma
tokentype(::Type{AST.InlineCode}) = Tokens.BackApostrophe

const AllowedBeforeAttachedModifierOpening = Union{Token{Tokens.Whitespace},
                                                   Token{
                                                         <:Tokens.AbstractPunctuation
                                                         },
                                                   Nothing}
const ForbiddenAfterAttachedModifierOpening = Union{Token{Tokens.Whitespace},
                                                    Nothing}
const AllowedAfterAttachedModifier = Union{Token{Tokens.Whitespace},
                                           Token{<:Tokens.AbstractPunctuation},
                                           Nothing}

function match_norg(::Type{AST.NorgDocument}, ast_node, token, parents, tokens, i)
    match_norg(AST.ParagraphSegment, ast_node, token, parents, tokens, i)
end

function match_norg(::Type{AST.Paragraph}, ast_node, token, parents, tokens, i)
    match_norg(AST.ParagraphSegment, ast_node, token, parents, tokens, i)
end

function match_norg(::Type{AST.ParagraphSegment}, ast_node, token, parents, tokens, i)
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
       MatchFound{ast_node}()
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Type{AST.LinkLocation}, ast_node, token, parents, tokens, i)
    MatchFound{AST.Word}()
end

function match_norg(::Type{<:AST.MatchedInline}, ast_node, token, parents, tokens, i)
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
       MatchFound{ast_node}()
    elseif !(last_token isa Token{Tokens.Whitespace}) &&
           next_token isa AllowedAfterAttachedModifier
        if any(t -> tokens[i] isa Token{tokentype(t)},
               filter(x -> x <: AST.MatchedInline, parents))
            MatchClosing{ast_node}()
        else
            MatchFound{AST.Word}()
        end
    else
        MatchFound{AST.Word}()
    end
end

function match_norg(::Type{AST.InlineCode}, ast_node, token, parents, tokens, i)
    token = tokens[i]
    if !(token isa Token{Tokens.BackApostrophe})
        return MatchFound{AST.Word}()
    end
    next_i = nextind(tokens, i)
    next_token = get(tokens, next_i, nothing)
    prev_i = prevind(tokens, i)
    last_token = get(tokens, prev_i, nothing)
    if last_token isa AllowedBeforeAttachedModifierOpening &&
       !(next_token isa ForbiddenAfterAttachedModifierOpening)
       MatchFound{ast_node}()
    elseif !(last_token isa Token{Tokens.Whitespace}) &&
           next_token isa AllowedAfterAttachedModifier
           MatchClosing{ast_node}()
    else
        MatchFound{AST.Word}()
    end
end

