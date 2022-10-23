"""
Provides the scanners for the tokenizer.

The role of a scanner is to recognize a sequence of characters and to produce a
`ScanResult`.
"""
module Scanners

using ..Kinds
using ..Tokens

struct ScanResult
    length::Int64
end
ScanResult(res::Bool) = if res ScanResult(1) else ScanResult(0) end
success(scanresult::ScanResult) = scanresult.length > 0

abstract type ScanStrategy end
struct Word <: ScanStrategy end
struct Whitespace <: ScanStrategy end
struct LineEnding <: ScanStrategy end
struct Punctuation <: ScanStrategy end

"""
    scan(pattern, input)

Scan the given `input` for the given `pattern`.

It will produce a [`ScanResult`](@ref).

If `pattern` is given, then try to fit the given patter at the start of `input`.
If `pattern` is :

  - a `ScanStrategy` subtype : scan with the given strategy (e.g. `Word` or `Whitespace`) 
  - a `Kind` : parse for the given kind.
  - an `AbstractString` : `input` must `startswith` `pattern`.
  - an `AbstractArray` : call `scan` on each element of `pattern` until one matches.
  - a `Set{Char}` : first character must be included in `pattern`.

"""
function scan end

function scan(s::AbstractString, input)
    if startswith(input, s)
        ScanResult(length(s))
    else
        ScanResult(false)
    end
end

function scan(list::AbstractArray, input)
    res = ScanResult(false)
    for pattern in list
        res = scan(pattern, input)::ScanResult
        if success(res)
            break
        end
    end
    res
end

function scan(set::Set{Char}, input)
    if first(input) ∈ set
        ScanResult(true)
    else
        ScanResult(false)
    end
end

include("assets/norg_whitespace.jl")
function scan(::Whitespace, input)
    trial_stop = 0
    for i in eachindex(input)
        if input[i] ∈ NORG_WHITESPACES
            trial_stop = i
        else
            break
        end
    end
    ScanResult(trial_stop)
end

function scan(::Word, input)
    trial_stop = 0
    for i in eachindex(input)
        teststr = SubString(input, i)
        test_whitespace = scan(Whitespace(), teststr)
        test_endline = scan(LineEnding(), teststr)
        test_punctuation = scan(Punctuation(), teststr)
        if !success(test_whitespace) && !success(test_endline) && !success(test_punctuation)
            trial_stop = i
        else
            break
        end
    end
    ScanResult(trial_stop)
end

scan(::LineEnding, input) = scan(NORG_LINE_ENDING, input)
scan(::Punctuation, input) = scan(NORG_PUNCTUATION, input)

include("assets/norg_line_ending.jl")
include("assets/norg_punctuation.jl")
function scan(kind::Kind, input)
    if kind == K"LineEnding"
        scan(LineEnding(), input)
    elseif kind == K"Punctuation"
        scan(Punctuation(), input)
    elseif kind == K"Whitespace"
        scan(Whitespace(), input)
    elseif kind == K"Word"
        scan(Word(), input)
    else # We rely on the user providing something that makes sense here.
        scan(string(kind), input)
    end
end

"""
All the registered [`TokenType`](@ref) that [`scan`](@ref) will try when consuming entries.
"""
const TOKENKIND_PARSING_ORDER = [
        Kinds.all_single_punctuation_tokens()...;
        K"LineEnding"; K"Whitespace"; K"Punctuation"; K"Word"
]

"""
    scan(input; line=0, charnum=0)

Scan the given `input` for [`TOKENKIND_PARSING_ORDER`](@ref) until one returns a
successful [`ScanResult`](@ref) or throw an error if none succeed.

This will return a [`Token`](@ref).
"""
function scan(input; line=0, charnum=0)
    res = ScanResult(false)
    tokentype = K"None"
    for scanner in TOKENKIND_PARSING_ORDER
        res = scan(scanner, input)
        if success(res)
            tokentype = scanner
            break
        end
    end
    if !success(res)
        error("No suitable token found for input at line $line, char $charnum")
    end
    Token(tokentype, line, charnum, input[1:res.length])
end

export scan

end
