"""
The role of this module is solely to produce a `DataStructures.Queue` of tokens from an input.
"""
module Tokenize

using DataStructures

using ..Tokens
using ..Scanners

function tokenize(input::AbstractString)
    linenum = 1
    linestart = firstindex(input)
    charnum = firstindex(input) 
    i = firstindex(input)
    result = Queue{Token}()
    while i <= lastindex(input)
        sub = SubString(input, i)
        token = Scanners.scan(sub, line=linenum, charnum=charnum)
        if token isa Tokens.Token{Tokens.LineEnding}
            linenum += 1
            charnum = 1
        else
            charnum += length(token)
        end
        enqueue!(result, token)
        i = nextind(input, i, length(token))
    end
    result
end

end
