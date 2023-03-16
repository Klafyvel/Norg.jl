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
struct Token{T}
    kind::Kind
    position::TokenPosition
    value::T
    Token{T}(kind, line, char, value) where {T} = new(kind, TokenPosition(line, char), value)
end

"""
    viewtype(s)

Returns the type returned by `Base.view` for the given string. Overload this
to make `Token`s based on your custom string type type-stable.
"""
viewtype(::T) where {T<:AbstractString} = SubString{T}

"""
     Token(kind, line, char, value)

Create a `Token` of kind `kind` with value `value` at `line` and char number `char`.
"""
Token(kind, line, char, value::T) where {T} = Token{T}(kind, line, char, value)

function Base.show(io::IO, token::Token)
    print(io,
    "$(kind(token)): $(repr(value(token))), line $(line(token)) col. $(char(token))")
end
SOFToken(input) = Token(K"StartOfFile", 0, 0, view(input, firstindex(input):lastindex(input)))
EOFToken(input) = Token(K"EndOfFile", 0, 0, view(input, firstindex(input):lastindex(input)))
line(t::Token) = line(t.position)
char(t::Token) = char(t.position)
value(t::Token) = t.value
Base.length(t::Token) = length(value(t))::Int

# Kind interface
const ATTACHED_DELIMITERS = KSet"* / _ - ! ^ , ` $ & %"
Kinds.kind(t::Token) = t.kind

export line, char, value
export Token, SOFToken, EOFToken, ATTACHED_DELIMITERS
end
