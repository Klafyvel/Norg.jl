"""
The role of this module is solely to produce a `DataStructures.Queue` of tokens from an input.
"""
module Tokenize

using ..Tokens
using ..Scanners

function tokenize(input::AbstractString)
    linenum = 1
    charnum = firstindex(input)
    i = firstindex(input)
    result = Vector{Token}()
    while i <= lastindex(input)
        sub = SubString(input, i)
        token = Scanners.scan(sub, line = linenum, charnum = charnum)
        if token isa Tokens.Token{Tokens.LineEnding}
            linenum += 1
            charnum = 1
        else
            charnum += length(token)
        end
        push!(result, token)
        i = nextind(input, i, length(token))
    end
    result
end

export tokenize

end
