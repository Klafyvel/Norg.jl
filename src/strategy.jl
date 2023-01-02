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
struct LeftParenthesis <: FromToken end
struct RightParenthesis <: FromToken end
struct Tilde <: FromToken end
struct GreaterThanSign <: FromToken end
struct LesserThanSign <: FromToken end
struct CommercialAtSign <: FromToken end
struct Plus <: FromToken end
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
struct NestableItem <: FromNode end
abstract type Tag <: FromNode end
struct Verbatim <: Tag end
struct WeakCarryoverTag <: FromNode end
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
struct URLLocation <: FromNode end
struct LineNumberLocation <: FromNode end
struct DetachedModifierLocation <: FromNode end
struct FileLocation <: FromNode end
struct MagicLocation <: FromNode end
struct NorgFileLocation <: FromNode end
struct WikiLocation <: FromNode end
struct TimestampLocation <: FromNode end
struct LinkDescription <: FromNode end
struct LinkSubTarget <: FromNode end
struct InlineLinkTarget <: FromNode end
struct ParagraphSegment <: FromNode end
struct Paragraph <: FromNode end
struct Escape <: FromNode end
abstract type AbstractDetachedModifierExtension end
struct DetachedModifierExtension <: AbstractDetachedModifierExtension end
struct TodoExtension <: AbstractDetachedModifierExtension end
abstract type TodoStatus <: AbstractDetachedModifierExtension end
struct StatusUndone <: TodoStatus end
struct StatusDone <: TodoStatus end
struct StatusNeedFurtherInput <: TodoStatus end
struct StatusUrgent <: TodoStatus end
struct StatusRecurring <: TodoStatus end
struct StatusInProgress <: TodoStatus end
struct StatusOnHold <: TodoStatus end
struct StatusCancelled <: TodoStatus end
struct TimestampExtension <: AbstractDetachedModifierExtension end
struct PriorityExtension <: AbstractDetachedModifierExtension end
struct DueDateExtension <: AbstractDetachedModifierExtension end
struct StartDateExtension <: AbstractDetachedModifierExtension end

export Whitespace, LineEnding, Star, Slash, Underscore, Minus, ExclamationMark
export Circumflex, Comma, BackApostrophe, BackSlash, EqualSign, LeftBrace
export RightBrace, RightSquareBracket, LeftSquareBracket, Tilde
export GreaterThanSign, LesserThanSign, CommercialAtSign, Plus

export FromNode, Word
export LeftParenthesis, RightParenthesis
export Heading, HeadingTitle, DelimitingModifier, StrongDelimiter
export WeakDelimiter, HorizontalRule, Nestable, UnorderedList, OrderedList
export Quote, NestableItem, Tag, Verbatim, WeakCarryoverTag, AttachedModifierStrategy, Bold, Italic 
export Underline, Strikethrough, Spoiler, Superscript, Subscript, InlineCode 
export Anchor, Link, LinkLocation, URLLocation, LineNumberLocation 
export DetachedModifierLocation, FileLocation, MagicLocation, NorgFileLocation 
export WikiLocation, TimestampLocation, LinkDescription, LinkSubTarget, InlineLinkTarget 
export DetachedModifierExtension
export TodoExtension, TimestampExtension, PriorityExtension, DueDateExtension, StartDateExtension
export StatusUndone, StatusDone, StatusNeedFurtherInput, StatusUrgent
export StatusRecurring, StatusInProgress, StatusOnHold, StatusCancelled
export ParagraphSegment, Paragraph, Escape

end

