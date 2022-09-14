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
struct Star <: AbstractPunctuation  end
struct Slash <: AbstractPunctuation end
struct Underscore <: AbstractPunctuation end
struct Minus <: AbstractPunctuation end
struct Circumflex <: AbstractPunctuation end
struct VerticalBar <: AbstractPunctuation end
struct BackApostrophe <: AbstractPunctuation end
struct BackSlash <: AbstractPunctuation end
struct LeftBrace <: AbstractPunctuation end
struct RightBrace <: AbstractPunctuation end
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
line(t::Token) = line(t.position)
char(t::Token) = char(t.position)
Base.length(t::Token) = length(t.value)

export line, char, Token
end
