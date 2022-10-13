"""
Provides the scanners for the tokenizer.

The role of a scanner is to recognize a sequence of characters and to produce a
[`Token`](@ref) or `nothing` from that.
"""
module Scanners

using ..Tokens

struct ScanResult
    length::Int64
end
ScanResult(res::Bool) = if res ScanResult(1) else ScanResult(0) end
success(scanresult::ScanResult) = scanresult.length > 0

"""
    scan(::TokenType, input)
    scan(pattern, input)

Scan the given `input` for the given `TokenType` or a `pattern`.

It will produce a [`ScanResult`](@ref).

If `pattern` is given, then try to fit the given patter at the start of `input`.
If `pattern` is :

  - a `Char` : first character must be `pattern` for a match.
  - an `AbstractString` : `input` must `startswith` `pattern`.
  - an `AbstractArray` : call `scan` on each element of `pattern` until one matches.
  - a `Set{Char}` : first character must be included in `pattern`.
"""
function scan end

scan(c::Char, input) = ScanResult(first(input) == c)

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

include("assets/norg_line_ending.jl")
scan(::Tokens.LineEnding, input) = scan(NORG_LINE_ENDING, input)

include("assets/norg_punctuation.jl")
scan(::Tokens.Punctuation, input) = scan(NORG_PUNCTUATION, input)

scan(::Tokens.Star, input) = scan('*', input)
scan(::Tokens.Slash, input) = scan('/', input)
scan(::Tokens.Underscore, input) = scan('_', input)
scan(::Tokens.Minus, input) = scan('-', input)
scan(::Tokens.ExclamationMark, input) = scan('!', input)
scan(::Tokens.Circumflex, input) = scan('^', input)
scan(::Tokens.Comma, input) = scan(',', input)
scan(::Tokens.BackApostrophe, input) = scan('`', input)
scan(::Tokens.BackSlash, input) = scan('\\', input)
scan(::Tokens.LeftBrace, input) = scan('{', input)
scan(::Tokens.RightBrace, input) = scan('}', input)
scan(::Tokens.LeftSquareBracket, input) = scan('[', input)
scan(::Tokens.RightSquareBracket, input) = scan(']', input)
scan(::Tokens.Tilde, input) = scan('~', input)
scan(::Tokens.GreaterThanSign, input) = scan('>', input)
scan(::Tokens.CommercialAtSign, input) = scan('@', input)
scan(::Tokens.EqualSign, input) = scan('=', input)
scan(::Tokens.Dot, input) = scan('.', input)
scan(::Tokens.Colon, input) = scan(':', input)
scan(::Tokens.NumberSign, input) = scan('#', input)
scan(::Tokens.DollarSign, input) = scan('$', input)

include("assets/norg_whitespace.jl")
function scan(::Tokens.Whitespace, input)
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

function scan(::Tokens.Word, input)
    trial_stop = 0
    for i in eachindex(input)
        teststr = SubString(input, i)
        test_whitespace = scan(Tokens.Whitespace(), teststr)
        test_endline = scan(Tokens.LineEnding(), teststr)
        test_punctuation = scan(Tokens.Punctuation(), teststr)
        if !success(test_whitespace) && !success(test_endline) && !success(test_punctuation)
            trial_stop = i
        else
            break
        end
    end
    ScanResult(trial_stop)
end

"""
All the registered [`TokenType`](@ref) that [`scan`](@ref) will try when consuming entries.
"""
const REGISTERED_TOKENTYPES = [
    Tokens.Star(),
    Tokens.Slash(),
    Tokens.Underscore(),
    Tokens.Minus(),
    Tokens.ExclamationMark(),
    Tokens.Circumflex(),
    Tokens.Comma(),
    Tokens.BackApostrophe(),
    Tokens.BackSlash(),
    Tokens.LeftBrace(),
    Tokens.RightBrace(),
    Tokens.LeftSquareBracket(),
    Tokens.RightSquareBracket(),
    Tokens.Tilde(),
    Tokens.GreaterThanSign(),
    Tokens.CommercialAtSign(),
    Tokens.EqualSign(),
    Tokens.Dot(),
    Tokens.Colon(),
    Tokens.NumberSign(),
    Tokens.DollarSign(),
    Tokens.LineEnding(),
    Tokens.Whitespace(),
    Tokens.Punctuation(),
    Tokens.Word(),
]

"""
    scan(input; line=0, charnum=0)

Scan the given `input` for [`REGISTERED_TOKENTYPES`](@ref) until one returns a
successful [`ScanResult`](@ref) or throw an error if none succeed.

This will return a [`Token`](@ref).
"""
function scan(input; line=0, charnum=0)
    res = ScanResult(false)
    tokentype = nothing
    for scanner in REGISTERED_TOKENTYPES
        res = scan(scanner, input)::ScanResult
        if success(res)
            tokentype = scanner
            break
        end
    end
    if !success(res)
        error("No suitable token found for input at line $line, char $charnum")
    end
    Token{typeof(tokentype)}(line, charnum, input[1:res.length])
end

export scan

end
