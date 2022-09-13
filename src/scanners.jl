"""
Provides the scanners for the tokenizer.

The role of a scanner is to recognize a sequence of characters and to produce a
`Token` or `nothing` from that.
"""
module Scanners

using ..Tokens

abstract type Scanner end

"""
    scan([scanner,] input; line=nothing, charnum=nothing)

Scan the given `input` using the given `scanner`. It will produce a `Token` or
`nothing` if the input does not match the `scanner`.

`line` and `charnum` are intended to give the current position in the buffer.

If no `scanner` is provided, will try the ones in `REGISTERED_SCANNERS` until one returns a `Token` or throw an error if none succeed.
"""
function scan end

function scan(c::Char, token_type, input; line=nothing, charnum=nothing)
    if first(input) == c
        Token(token_type, line, charnum, input[1:1])
    else
        nothing
    end
end

function scan(s::AbstractString, token_type, input; line=nothing, charnum=nothing)
    l = length(s)
    if input[1:l] == s
        Token(token_type, line, charnum, input[1:l])
    else
        nothing
    end
end

function scan(list::AbstractArray, token_type, input; line=nothing, charnum=nothing)
    res = nothing
    for pattern in list
        res = scan(pattern, token_type, input; line=nothing, charnum=nothing)
        if !isnothing(res)
            break
        end
    end
    res
end

const NORG_LINE_ENDING = [
                              Char(0x000A),
                              Char(0x000D),
                              String([Char(0x000D), Char(0x000A)])
                             ]
struct LineEnding <: Scanner end
scan(::LineEnding, input; kwargs...) = scan(NORG_LINE_ENDING, Tokens.LineEnding(), input; kwargs...)

const NORG_WHITESPACES = Set([
        Char(0x0009), # tab
        Char(0x000A), # line feed
        Char(0x000C), # form feed
        Char(0x000D), # carriage return
        Char(0x0020), # space
        Char(0x00A0), # no-break space
        Char(0x1680), # Ogham space mark
        Char(0x2000), # en quad
        Char(0x2001), # em quad
        Char(0x2002), # en space
        Char(0x2003), # em space
        Char(0x2004), # three-per-em space
        Char(0x2005), # four-per-em space
        Char(0x2006), # six-per-em space
        Char(0x2007), # figure space
        Char(0x2008), # punctuation space
        Char(0x2009), # thin space
        Char(0x200A), # hair space
        Char(0x202F), # narrow no-break space
        Char(0x205F), # medium mathematical space
        Char(0x3000), # ideographic space
    ])

struct Whitespace <: Scanner end
function scan(::Whitespace, input; line=nothing, charnum=nothing)
    trial_start = firstindex(input)
    trial_stop = nothing
    for i in eachindex(input)
        if input[i] ∈ NORG_WHITESPACES
            trial_stop = i
        else
            break
        end
    end
    if !isnothing(trial_stop)    
        Token(Tokens.Whitespace(), line, charnum, input[trial_start:trial_stop])
    else
        nothing
    end
end

const REGISTERED_SCANNERS = [
                             LineEnding(),
                             Whitespace()
]

function scan(input; line=nothing, charnum=nothing)
    res = nothing
    for scanner in REGISTERED_SCANNERS
        res = scan(scanner, input, line; line=line, charnum=charnum)
        if !isnothing(res)
            break
        end
    end
    if isnothing(res)
        error("No suitable token found for input at line $line, char $charnum")
    end
    res
end

export scan

end
