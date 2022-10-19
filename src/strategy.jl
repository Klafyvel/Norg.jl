module Strategies

abstract type Strategy end
abstract type FromToken <: Strategy end
struct Whitespace <: FromToken end
struct LineEnding <: FromToken end
struct Star <: FromToken end
struct Slash <: FromToken end
struct Underscore <: FromToken end
struct Minus <: FromToken end
struct ExclamationMark <: FromToken end
struct Circumflex <: FromToken end
struct Comma <: FromToken end
struct BackApostrophe <: FromToken end
struct BackSlash <: FromToken end
struct EqualSign <: FromToken end
struct LeftBrace <: FromToken end
struct RightBrace <: FromToken end
struct RightSquareBracket <: FromToken end
struct LeftSquareBracket <: FromToken end
struct Tilde <: FromToken end
struct GreaterThanSign <: FromToken end
struct CommercialAtSign <: FromToken end
abstract type FromNode <: Strategy end
struct Word <: FromNode end
struct Heading <: FromNode end
struct HeadingTitle <: FromNode end
abstract type DelimitingModifier <: FromNode end
struct StrongDelimiter <: DelimitingModifier end
struct WeakDelimiter <: DelimitingModifier end
struct HorizontalRule <: DelimitingModifier end
abstract type Nestable <: FromNode end
struct UnorderedList <: Nestable end
struct OrderedList <: Nestable end
struct Quote <: Nestable end
struct Verbatim <: FromNode end
abstract type AttachedModifierStrategy <: FromNode end
struct Bold <: AttachedModifierStrategy end
struct Italic <: AttachedModifierStrategy end
struct Underline <: AttachedModifierStrategy end
struct Strikethrough <: AttachedModifierStrategy end
struct Spoiler <: AttachedModifierStrategy end
struct Superscript <: AttachedModifierStrategy end
struct Subscript <: AttachedModifierStrategy end
struct InlineCode <: AttachedModifierStrategy end
struct Anchor <: FromNode end
struct Link <: FromNode end
struct LinkLocation <: FromNode end
struct LinkDescription <: FromNode end
struct LinkSubTarget <: FromNode end
struct ParagraphSegment <: FromNode end
struct Paragraph <: FromNode end
struct Escape <: FromNode end

export Whitespace, LineEnding, Star, Slash, Underscore, Minus, ExclamationMark, Circumflex, Comma, BackApostrophe, BackSlash, EqualSign, LeftBrace, RightBrace, RightSquareBracket, LeftSquareBracket, Tilde, GreaterThanSign, CommercialAtSign, FromNode, Word, Heading, HeadingTitle, DelimitingModifier, StrongDelimiter, WeakDelimiter, HorizontalRule, Nestable, UnorderedList, OrderedList, Quote, Verbatim, AttachedModifierStrategy, Bold, Italic, Underline, Strikethrough, Spoiler, Superscript, Subscript, InlineCode, Anchor, Link, LinkLocation, LinkDescription, LinkSubTarget, ParagraphSegment, Paragraph, Escape

end

