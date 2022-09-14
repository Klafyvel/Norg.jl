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
    if startswith(input, s)
        Token(token_type, line, charnum, s)
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

function scan(set::Set{Char}, token_type, input; line=nothing, charnum=nothing)
    if first(input) ∈ set
        Token(token_type, line, charnum, input[1:1])
    else
        nothing
    end
end

include("assets/norg_line_ending.jl")
struct LineEnding <: Scanner end
scan(::LineEnding, input; kwargs...) = scan(NORG_LINE_ENDING, Tokens.LineEnding(), input; kwargs...)

include("assets/norg_punctuation.jl")
struct Punctuation <: Scanner end
scan(::Punctuation, input; kwargs...) = scan(NORG_PUNCTUATION, Tokens.Punctuation(), input; kwargs...)

include("assets/norg_whitespace.jl")
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
                             Whitespace(),
                             Punctuation(),
]

function scan(input; line=nothing, charnum=nothing)
    res = nothing
    for scanner in REGISTERED_SCANNERS
        res = scan(scanner, input; line=line, charnum=charnum)
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
