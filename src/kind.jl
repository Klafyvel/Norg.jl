"""
To provide a type-stable parser, we handle types ourselves. This is directly
inspired by JuliaSyntax.jl. See [here](https://github.com/JuliaLang/JuliaSyntax.jl/blob/384f74545d8d2a530ba3ec4a3a82469c34ed597d/src/kinds.jl#L905-L922)

You can see kinds as an advanced `Enum` type that allows some kind of grouping
of values. We use [`Kinds.Kind`](@ref) to classify the different types of tokens
ast nodes.
"""
module Kinds

"""
All the defined kind names.
"""
const _kind_names = [
  "None"
  "StartOfFile"
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
    "<"
    "@"
    "="
    "."
    "\$"
    ":"
    "#"
  "END_PUNCTUATION"
  "Word"

  # AST stuff
  "NorgDocument"
  "BEGIN_AST_NODE"
    # Leafs contain a set of tokens.
    "BEGIN_AST_LEAF"
      "WordNode" 
      "Number"
      "VerbatimBody"
      "VerbatimTag"
      "VerbatimParameter"
      "HeadingPreamble"
      "NestablePreamble"
      "LineNumberTarget"
      "URLTarget"
      "FileTarget"
      "FileNorgRootTarget"
    "END_AST_LEAF"
    "Paragraph"
    "ParagraphSegment"
    "Escape"
    "Link"
    "LinkLocation"
    "Anchor"
    "NestableItem"
    "Verbatim"
    "HeadingTitle"
    "BEGIN_MATCHED_INLINE"
      "BEGIN_ATTACHED_MODIFIER"
        "Bold"
        "Italic"
        "Underline" 
        "Strikethrough"
        "Spoiler"
        "Superscript"
        "Subscript"
        "InlineCode"
      "END_ATTACHED_MODIFIER"
      "BEGIN_LINK_LOCATION"
        "URLLocation"
        "LineNumberLocation"
        "DetachedModifierLocation"
        "MagicLocation"
        "FileLocation"
        "NorgFileLocation"
      "END_LINK_LOCATION"
      "LinkDescription"
      "LinkLocation"
      "InlineLinkTarget"
    "END_MATCHED_INLINE"
    "BEGIN_DETACHED_MODIFIER"
      "BEGIN_HEADING"
        "Heading1"
        "Heading2"
        "Heading3"
        "Heading4"
        "Heading5"
        "Heading6"
      "END_HEADING"
      "BEGIN_DELIMITING_MODIFIER"
        "WeakDelimitingModifier"
        "StrongDelimitingModifier"
        "HorizontalRule"
      "END_DELIMITING_MODIFIER"
      "BEGIN_NESTABLE"
        "BEGIN_UNORDERED_LIST"
          "UnorderedList1"
          "UnorderedList2"
          "UnorderedList3"
          "UnorderedList4"
          "UnorderedList5"
          "UnorderedList6"
        "END_UNORDERED_LIST"
        "BEGIN_ORDERED_LIST"
          "OrderedList1"
          "OrderedList2"
          "OrderedList3"
          "OrderedList4"
          "OrderedList5"
          "OrderedList6"
        "END_ORDERED_LIST"
        "BEGIN_QUOTE"
          "Quote1"
          "Quote2"
          "Quote3"
          "Quote4"
          "Quote5"
          "Quote6"
        "END_QUOTE"
      "END_NESTABLE"
    "END_DETACHED_MODIFIER"
  "END_AST_NODE"
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
kind(::Nothing) = K"None"

#######################
# Ensemble predicates #
#######################

# AST
is_leaf(k::Kind) = K"BEGIN_AST_LEAF" < k < K"END_AST_LEAF"
is_matched_inline(k::Kind) = K"BEGIN_MATCHED_INLINE" < k < K"END_MATCHED_INLINE"
is_attached_modifier(k::Kind) = K"BEGIN_ATTACHED_MODIFIER" < k < K"END_ATTACHED_MODIFIER"
is_link_location(k::Kind) = K"BEGIN_LINK_LOCATION" < k < K"END_LINK_LOCATION"
is_detached_modifier(k::Kind) = K"BEGIN_DETACHED_MODIFIER" < k < K"END_DETACHED_MODIFIER"
is_delimiting_modifier(k::Kind) = K"BEGIN_DELIMITING_MODIFIER" < k < K"END_DELIMITING_MODIFIER"
is_nestable(k::Kind) = K"BEGIN_NESTABLE" < k < K"END_NESTABLE"
is_heading(k::Kind) = K"BEGIN_HEADING" < k < K"END_HEADING"
is_unordered_list(k::Kind) = K"BEGIN_UNORDERED_LIST" < k < K"END_UNORDERED_LIST"
is_ordered_list(k::Kind) = K"BEGIN_ORDERED_LIST" < k < K"END_ORDERED_LIST"
is_quote(k::Kind) = K"BEGIN_QUOTE" < k < K"END_QUOTE"

export @K_str, @KSet_str, Kind, kind, is_leaf, is_matched_inline, is_attached_modifier, is_link_location, is_detached_modifier, is_delimiting_modifier, is_nestable, is_heading, is_unordered_list, is_ordered_list, is_quote

end
