"""
Produce [`Tokens.Token`](@ref) vectors from a string using [`tokenize`](@ref).
"""
module Tokenize

using ..Kinds
using ..Tokens
using ..Scanners

"""
    tokenize(input)

Produce [`Tokens.Token`](@ref) vectors from an input string.
"""
function tokenize(input::AbstractString)
    linenum = 1
    charnum = firstindex(input)
    i = firstindex(input)
    result = [SOFToken()]
    while i <= lastindex(input)
        sub = SubString(input, i)
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
    push!(result, EOFToken())
    result
end

export tokenize

end
