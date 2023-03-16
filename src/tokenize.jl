"""
Produce [`Tokens.Token`](@ref) vectors from a string using [`tokenize`](@ref).
"""
module Tokenize

using ..Kinds
using ..Tokens
using ..Scanners

"""
    queuetype(s)

Returns the type of queue that should be used for this type of strings. Overload
this to replace the default `Vector` used.
"""
queuetype(::T) where {T<:AbstractString} = Vector

"""
    tokenize(input)

Produce [`Tokens.Token`](@ref) vectors from an input string.
"""
function tokenize(input::AbstractString)
    linenum = 1
    charnum = firstindex(input)
    result = queuetype(input){Token{Tokens.viewtype(input)}}()
    push!(result, SOFToken(input))
    i = firstindex(input)
    while i < lastindex(input)
        sub = view(input, i:lastindex(input))
        token = Scanners.scan(sub, line = linenum, charnum = charnum)
        if is_line_ending(token)
            linenum += 1
            charnum = 1
        else
            charnum += length(token)
        end
        push!(result, token)
        i = nextind(input, i, length(token))
    end
    push!(result, EOFToken(input))
    result
end

export tokenize

end
