"""
Provides the tokens for the tokenizer.

A [`Token`](@ref) stores its value, a [`TokenType`](@ref) and a [`TokenPosition`](@ref)
"""
module Tokens

abstract type TokenType end
abstract type AbstractWhitespace <: TokenType end
struct LineEnding <: AbstractWhitespace end
struct Whitespace <: AbstractWhitespace end
abstract type AbstractPunctuation <: TokenType end
struct Punctuation <: AbstractPunctuation end
abstract type AttachedModifierPunctuation <: AbstractPunctuation end
struct Star <: AttachedModifierPunctuation  end
struct Slash <: AttachedModifierPunctuation end
struct Underscore <: AttachedModifierPunctuation end
struct Minus <: AttachedModifierPunctuation end
struct ExclamationMark <: AttachedModifierPunctuation end
struct Circumflex <: AttachedModifierPunctuation end
struct Comma <: AttachedModifierPunctuation end
struct BackApostrophe <: AttachedModifierPunctuation end
struct Percent <: AttachedModifierPunctuation end
struct BackSlash <: AttachedModifierPunctuation end
struct LeftBrace <: AttachedModifierPunctuation end
struct RightBrace <: AttachedModifierPunctuation end
struct Word <: TokenType end

struct TokenPosition
    line
    char
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

struct Token{T<:TokenType}
    position::TokenPosition
    value
end
"""
     Token(line, char, type, value)

Create a `Token` of type `type` with value `value` at `line` and char number `char`.
"""
Token(::T, line, char, value) where T<:TokenType = Token{T}(TokenPosition(line, char), value)
Base.show(io::IO, token::Token) = print(io, "$(repr(value(token))), line $(line(token)) col. $(char(token))")
line(t::Token) = line(t.position)
char(t::Token) = char(t.position)
Base.length(t::Token) = length(t.value)
value(t::Token) = t.value

export line, char, value, Token
end
