"""
Provides the tokens for the tokenizer.

A [`Tokens.Token`](@ref) stores its value, a [`Kinds.Kind`](@ref) and a [`Tokens.TokenPosition`](@ref)
"""
module Tokens

using ..Kinds

"""
Stores the position of a token in the input file (line and char).
"""
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

"""
A Norg Token has a [`Kinds.kind`](@ref) (*i.e.* `K"EndLine"`), a `position`, and
a `value`.

See also: [`Tokens.TokenPosition`](@ref)
"""
struct Token
    kind::Kind
    position::TokenPosition
    value::SubString{String}
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
    "Token(K\"$(string(kind(token)))\", \"$(value(token))\", line $(string(line(token))), col. $(string(char(token))))")
end
SOFToken() = Token(K"StartOfFile", 0, 0, SubString(""))
EOFToken() = Token(K"EndOfFile", 0, 0, SubString(""))
line(t::Token) = line(t.position)
char(t::Token) = char(t.position)
value(t::Token) = t.value
Base.length(t::Token) = length(value(t))::Int

# Kind interface
const ATTACHED_DELIMITERS = KSet"* / _ - ! ^ , ` $ & %"
Kinds.kind(t::Token) = t.kind
is_whitespace(t::Token) = K"BEGIN_WHITESPACE" < kind(t) < K"END_WHITESPACE"
is_punctuation(t::Token) = K"BEGIN_PUNCTUATION" < kind(t) < K"END_PUNCTUATION"
is_word(t::Token) = kind(t) == K"Word"
is_line_ending(t::Token) = kind(t) == K"LineEnding"
is_sof(t::Token) = kind(t) == K"StartOfFile"
is_eof(t::Token) = kind(t) == K"EndOfFile"

export line, char, value, is_whitespace, is_punctuation, is_word
export is_line_ending, Token, is_sof, is_eof, SOFToken, EOFToken, ATTACHED_DELIMITERS
end
