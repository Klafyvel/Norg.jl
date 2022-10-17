"""
To provide a type-stable parser, we handle types ourselves. This is directly
inspired by JuliaSyntax.jl. See [here](https://github.com/JuliaLang/JuliaSyntax.jl/blob/384f74545d8d2a530ba3ec4a3a82469c34ed597d/src/kinds.jl#L905-L922)
"""
module Kinds

const _kind_names = [
    "None"
    "EndOfFile"
    "BEGIN_WHITESPACE"
        "LineEnding"
        "Whitespace"
    "END_WHITESPACE"
    "BEGIN_PUNCTUATION"
        "Punctuation"
        "\\"
        "*"
        "/"
        "_"
        "-"
        "!"
        "^"
        ","
        "`"
        "{"
        "}"
        "["
        "]"
        "~"
        ">"
        "@"
        "="
        "."
        "\$"
        ":"
        "#"
    "END_PUNCTUATION"
    "Word"

]


"""
    Kind(name)
    K"name"

This is type tag, used to specify the type of tokens and AST nodes.
"""
primitive type Kind 8 end

let kind_int_type = :UInt8,
    max_kind_int = length(_kind_names)-1

    @eval begin
        function Kind(x::Integer)
            if x < 0 || x > $max_kind_int
                throw(ArgumentError("Kind out of range: $x"))
            end
            return Base.bitcast(Kind, convert($kind_int_type, x))
        end

        Base.convert(::Type{String}, k::Kind) = _kind_names[1 + Base.bitcast($kind_int_type, k)]

        let kindstr_to_int = Dict(s=>i-1 for (i,s) in enumerate(_kind_names))
            function Base.convert(::Type{Kind}, s::AbstractString)
                i = get(kindstr_to_int, s) do
                    error("unknown Kind name $(repr(s))")
                end
                Kind(i)
            end
        end

        Base.string(x::Kind) = convert(String, x)
        Base.print(io::IO, x::Kind) = print(io, convert(String, x))

        Base.typemin(::Type{Kind}) = Kind(0)
        Base.typemax(::Type{Kind}) = Kind($max_kind_int)

        Base.instances(::Type{Kind}) = (Kind(i) for i in reinterpret($kind_int_type, typemin(Kind)):reinterpret($kind_int_type, typemax(Kind)))
        Base.:<(x::Kind, y::Kind) = reinterpret($kind_int_type, x) < reinterpret($kind_int_type, y)

        all_single_punctuation_tokens() = (Kind(i) for i in (reinterpret($kind_int_type, convert(Kind, "Punctuation"))+1):(reinterpret($kind_int_type, convert(Kind, "END_PUNCTUATION"))-1))
    end
end

function Base.show(io::IO, k::Kind)
    print(io, "K\"$(convert(String, k))\"")
end

"""
    K"s"
The kind of a token or AST internal node with string "s".
For example
* K">" is the kind of the greater than sign token
"""
macro K_str(s)
    convert(Kind, s)
end

"""
A set of kinds which can be used with the `in` operator.  For example
    k in KSet"+ - *"
"""
macro KSet_str(str)
    kinds = [convert(Kind, s) for s in split(str)]

    quote
        ($(kinds...),)
    end
end

"""
    kind(x)
Return the `Kind` of `x`.
"""
kind(k::Kind) = k

is_whitespace(k::Kind) = K"BEGIN_WHITESPACE" < k < K"END_WHITESPACE"
is_punctuation(k::Kind) = K"BEGIN_PUNCTUATION" < k < K"END_PUNCTUATION"
is_word(k::Kind) = k == K"Word"
is_line_ending(k::Kind) = k == K"LineEnding"

export @K_str, @KSet_str, Kind, is_whitespace, is_punctuation, is_word, is_line_ending, kind

end
