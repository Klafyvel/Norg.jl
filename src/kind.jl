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
    "%"
    "&"
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
    "?"
    "("
    ")"
    "|"
    "+"
  "END_PUNCTUATION"
  "x"
  "Word"

  # AST stuff
  "NorgDocument"
  "BEGIN_AST_NODE"
    # Leafs contain a set of tokens.
    "BEGIN_AST_LEAF"
      "WordNode" 
      "Number"
      "TagName"
      "TagParameter"
      "VerbatimBody"
      "HeadingPreamble"
      "NestablePreamble"
      "LineNumberTarget"
      "URLTarget"
      "FileTarget"
      "FileNorgRootTarget"
      "Timestamp"
      "BEGIN_TODO_STATUS"
        "StatusUndone"
        "StatusDone"
        "StatusNeedFurtherInput"
        "StatusUrgent"
        "StatusRecurring"
        "StatusInProgress"
        "StatusOnHold"
        "StatusCancelled"
      "END_TODO_STATUS"
    "END_AST_LEAF"
    "Paragraph"
    "ParagraphSegment"
    "Escape"
    "Link"
    "LinkLocation"
    "Anchor"
    "NestableItem"
    "RangeableItem"
    "StandardRangedTagBody"
    "BEGIN_TAG"
        "BEGIN_RANGED_TAG"
            "Verbatim"
        "END_RANGED_TAG"
        "BEGIN_CARRYOVER_TAG"
            "WeakCarryoverTag"
            "StrongCarryoverTag"
        "END_CARRYOVER_TAG"
        "StandardRangedTag"
    "END_TAG"
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
        "NullModifier"
        "InlineMath"
        "Variable"
        "BEGIN_FREE_FORM_ATTACHED_MODIFIER"
          "FreeFormBold"
          "FreeFormItalic"
          "FreeFormUnderline" 
          "FreeFormStrikethrough"
          "FreeFormSpoiler"
          "FreeFormSuperscript"
          "FreeFormSubscript"
          "FreeFormInlineCode"
          "FreeFormNullModifier"
          "FreeFormInlineMath"
          "FreeFormVariable"
        "END_FREE_FORM_ATTACHED_MODIFIER"
      "END_ATTACHED_MODIFIER"
      "BEGIN_LINK_LOCATION"
        "URLLocation"
        "LineNumberLocation"
        "DetachedModifierLocation"
        "MagicLocation"
        "FileLocation"
        "NorgFileLocation"
        "WikiLocation"
        "TimestampLocation"
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
      "BEGIN_DETACHED_MODIFIER_EXTENSIONS"
        "TodoExtension"
        "TimestampExtension"
        "PriorityExtension"
        "DueDateExtension"
        "StartDateExtension"
      "END_DETACHED_MODIFIER_EXTENSIONS"
      "BEGIN_RANGEABLE_DETACHED_MODIFIERS"
        "Definition"
        "TableCell"
        "Footnote"
      "END_RANGEABLE_DETACHED_MODIFIERS"
      "BEGIN_DETACHED_MODIFIER_SUFFIX"
        "Slide"
        "IndentSegment"
      "END_DETACHED_MODIFIER_SUFFIX"
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

# Tokens

is_whitespace(t) = K"BEGIN_WHITESPACE" < kind(t) < K"END_WHITESPACE"
is_punctuation(t) = K"BEGIN_PUNCTUATION" < kind(t) < K"END_PUNCTUATION"
is_word(t) = kind(t) == K"Word"
is_line_ending(t) = kind(t) == K"LineEnding"
is_sof(t) = kind(t) == K"StartOfFile"
is_eof(t) = kind(t) == K"EndOfFile"

# AST
is_leaf(k) = K"BEGIN_AST_LEAF" < kind(k) < K"END_AST_LEAF"
is_matched_inline(k) = K"BEGIN_MATCHED_INLINE" < kind(k) < K"END_MATCHED_INLINE"
is_attached_modifier(k) = K"BEGIN_ATTACHED_MODIFIER" < kind(k) < K"END_ATTACHED_MODIFIER"
is_free_form_attached_modifier(k) = K"BEGIN_FREE_FORM_ATTACHED_MODIFIER" < kind(k) < K"END_FREE_FORM_ATTACHED_MODIFIER"
is_link_location(k) = K"BEGIN_LINK_LOCATION" < kind(k) < K"END_LINK_LOCATION"
is_detached_modifier(k) = K"BEGIN_DETACHED_MODIFIER" < kind(k) < K"END_DETACHED_MODIFIER"
is_detached_modifier_extension(k) = K"BEGIN_DETACHED_MODIFIER_EXTENSIONS" < kind(k) < K"END_DETACHED_MODIFIER_EXTENSIONS"
is_delimiting_modifier(k) = K"BEGIN_DELIMITING_MODIFIER" < kind(k) < K"END_DELIMITING_MODIFIER"
is_nestable(k) = K"BEGIN_NESTABLE" < kind(k) < K"END_NESTABLE"
is_heading(k) = K"BEGIN_HEADING" < kind(k) < K"END_HEADING"
is_unordered_list(k) = K"BEGIN_UNORDERED_LIST" < kind(k) < K"END_UNORDERED_LIST"
is_ordered_list(k) = K"BEGIN_ORDERED_LIST" < kind(k) < K"END_ORDERED_LIST"
is_quote(k) = K"BEGIN_QUOTE" < kind(k) < K"END_QUOTE"
is_tag(k) = K"BEGIN_TAG" < kind(k) < K"END_TAG"
is_ranged_tag(k) = K"BEGIN_RANGED_TAG" < kind(k) < K"END_RANGED_TAG"
is_carryover_tag(k) = K"BEGIN_CARRYOVER_TAG" < kind(k) < K"END_CARRYOVER_TAG"

export @K_str, @KSet_str, Kind, kind
export is_whitespace, is_punctuation, is_word, is_line_ending, is_sof, is_eof
export is_leaf, is_matched_inline
export is_attached_modifier, is_link_location, is_detached_modifier
export is_delimiting_modifier, is_nestable, is_heading, is_unordered_list
export is_ordered_list, is_quote, is_detached_modifier_extension

end
