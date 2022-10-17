"""
Provides the tokens for the tokenizer.

A [`Token`](@ref) stores its value, a [`TokenType`](@ref) and a [`TokenPosition`](@ref)
"""
module Tokens

using ..Kinds

struct TokenPosition
    line::Int
    char::Int
end
"""
    line(x)

Return the line number corresponding to the position or token `x`.
"""
line(p::TokenPosition) = p.line
"""
    char(x)

Return the character number in the line corresponding to position or token `x`.
"""
char(p::TokenPosition) = p.char

struct Token
    kind::Kind
    position::TokenPosition
    value::SubString
end

"""
     Token(kind, line, char, value)

Create a `Token` of kind `kind` with value `value` at `line` and char number `char`.
"""
function Token(kind, line, char, value)
    Token(kind, TokenPosition(line, char), value)
end
function Base.show(io::IO, token::Token)
    print(io,
    "$(kind(token)): $(repr(value(token))), line $(line(token)) col. $(char(token))")
end
line(t::Token) = line(t.position)
char(t::Token) = char(t.position)
value(t::Token) = t.value
Base.length(t::Token) = length(value(t))

# Kind interface
Kinds.kind(t::Token) = t.kind
Kinds.is_whitespace(t::Token) = Kinds.is_whitespace(t.kind)
Kinds.is_punctuation(t::Token) = Kinds.is_punctuation(t.kind)
Kinds.is_word(t::Token) = Kinds.is_word(t.kind)
Kinds.is_line_ending(t::Token) = Kinds.is_line_ending(t.kind)

export line, char, value, Token
end
