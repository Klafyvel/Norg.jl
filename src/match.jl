"""This module exports `match_norg` which matches token sequences to [`AST.NodeData`](@ref) types."""
module Match
using ..AST
using ..Tokens

tokentype(::Type{AST.ParagraphSegment}) = Tokens.LineEnding
tokentype(::Type{AST.Bold}) = Tokens.Star
tokentype(::Type{AST.Italic}) = Tokens.Slash
tokentype(::Type{AST.Underline}) = Tokens.Underscore
tokentype(::Type{AST.Strikethrough}) = Tokens.Minus
tokentype(::Type{AST.Spoiler}) = Tokens.ExclamationMark
tokentype(::Type{AST.Superscript}) = Tokens.Circumflex
tokentype(::Type{AST.Subscript}) = Tokens.Comma
tokentype(::Type{AST.InlineCode}) = Tokens.BackApostrophe

const AllowedBeforeAttachedModifierOpening = Union{Token{Tokens.Whitespace},Token{<:Tokens.AbstractPunctuation},Nothing}
const ForbiddenAfterAttachedModifierOpening = Union{Token{Tokens.Whitespace},Nothing}
const AllowedAfterAttachedModifier = Union{Token{Tokens.Whitespace},Token{<:Tokens.AbstractPunctuation},Nothing}

function match_attached_modifier(::Type{AST.ParagraphSegment}, tokens, i, ast_node)
  next_i = nextind(tokens, i)
  next_token = get(tokens, next_i, nothing)
  prev_i = prevind(tokens, i)
  last_token = get(tokens, prev_i, nothing)
  if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
    ast_node
  else
    AST.Word
  end
end

function match_attached_modifier(T::Type{<:AST.AttachedModifier}, tokens, i, ast_node)
  next_i = nextind(tokens, i)
  next_token = get(tokens, next_i, nothing)
  prev_i = prevind(tokens, i)
  last_token = get(tokens, prev_i, nothing)
  if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
    ast_node
  elseif !(last_token isa Token{Tokens.Whitespace}) && next_token isa AllowedAfterAttachedModifier
    if tokens[i] isa Token{tokentype(T)}
      nothing
    else
      AST.Word
    end
  else
    AST.Word
  end
end

function match_attached_modifier(::Type{AST.InlineCode}, tokens, i, ast_node)
  token = tokens[i]
  if !(token isa Token{Tokens.BackApostrophe})
    return AST.Word
  end
  next_i = nextind(tokens, i)
  next_token = get(tokens, next_i, nothing)
  prev_i = prevind(tokens, i)
  last_token = get(tokens, prev_i, nothing)
  if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
    ast_node
  elseif !(last_token isa Token{Tokens.Whitespace}) && next_token isa AllowedAfterAttachedModifier
    nothing
  else
    AST.Word
  end
end

"""
  match_norg(token, parent, tokens, i)

Find the appropriate [`AST.NodeData`](@reg) for a `token` when parser is inside
a `parent` block parsing the `tokens` list at index `i`
"""
function match_norg end

match_norg(::Token, parent, tokens, i) = AST.Word
match_norg(::Token{Tokens.Star}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Bold)
match_norg(::Token{Tokens.Slash}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Italic)
match_norg(::Token{Tokens.Underscore}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Underline)
match_norg(::Token{Tokens.Minus}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Strikethrough)
match_norg(::Token{Tokens.ExclamationMark}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Spoiler)
match_norg(::Token{Tokens.Circumflex}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Superscript)
match_norg(::Token{Tokens.Comma}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.Subscript)
match_norg(::Token{Tokens.BackApostrophe}, parent, tokens, i) = match_attached_modifier(parent, tokens, i, AST.InlineCode)
match_norg(::Token{Tokens.BackSlash}, parent, tokens, i) = AST.Escape

export match_norg
end
