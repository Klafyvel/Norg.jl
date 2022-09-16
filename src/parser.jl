"""
This module defines the [`Parser.parse`](@ref) function, which builds an AST from a token list.
"""
module Parser

using ..Tokens
using ..Tokenize
using ..AST

function parse_norg end

Base.parse(::Type{AST.NorgDocument}, s::AbstractString) = last(parse_norg(Tokenize.tokenize(s)))
parse_norg(tokens) = parse_norg(AST.NorgDocument, tokens, firstindex(tokens))
parse_norg(T, tokens) = parse_norg(T, tokens, firstindex(tokens))

function parse_norg(::Type{AST.NorgDocument}, tokens, i)
    paragraphs = AST.Node[]
    while i <= lastindex(tokens)
        i, paragraph = parse_norg(AST.Paragraph, tokens, i)
        push!(paragraphs, paragraph)
    end
    i, AST.Node(paragraphs, AST.NorgDocument())
end

function parse_norg(::Type{AST.Paragraph}, tokens, i)
    segments = AST.Node[]
    while i <= lastindex(tokens)
        i, segment = parse_norg(AST.ParagraphSegment, tokens, i)
        push!(segments, segment)
        if i<=lastindex(tokens) && tokens[i] isa Token{Tokens.LineEnding}
            i = nextind(tokens, i)
            break
        end
    end
    i, AST.Node(segments, AST.Paragraph())
end

match(::Token) = AST.Word
match(::Token{Tokens.Star}) =  AST.Bold
match(::Token{Tokens.Slash}) =  AST.Italic
match(::Token{Tokens.Underscore}) =  AST.Underline
match(::Token{Tokens.Minus}) =  AST.Strikethrough
match(::Token{Tokens.ExclamationMark}) =  AST.Spoiler
match(::Token{Tokens.Circumflex}) =  AST.Superscript
match(::Token{Tokens.Comma}) =  AST.Subscript
match(::Token{Tokens.BackApostrophe}) =  AST.InlineCode
match(::Token{Tokens.BackSlash}) = AST.Escape

is_attached_modifier_delimiter(::Token{T}) where T <: Tokens.AttachedModifierPunctuation = true
is_attached_modifier_delimiter(::Token) = false

const AllowedBeforeAttachedModifierOpening = Union{Token{Tokens.Whitespace}, Token{<:Tokens.AbstractPunctuation}, Nothing}
const ForbiddenAfterAttachedModifierOpening = Union{Token{Tokens.Whitespace}, Nothing}
const AllowedAfterAttachedModifier = Union{Token{Tokens.Whitespace}, Token{<:Tokens.AbstractPunctuation}, Nothing}

function parse_norg(::Type{AST.ParagraphSegment}, tokens, i)
    children = AST.Node[]
    last_token = nothing
    # @info "paragraphsegment starting" i
    while i <= lastindex(tokens)
        token = tokens[i]
        # @info "paragraphsegment loop" i token
        if token isa Token{Tokens.LineEnding}
            # @info "Paragraph segment line ending !" token i
            i = nextind(tokens, i)
            break
        end
        if is_attached_modifier_delimiter(token)
            next_i = nextind(tokens, i)
            next_token = get(tokens, next_i, nothing)
            if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
                i, node = parse_norg(match(token), tokens, i)
            else
                i, node = parse_norg(AST.Word, tokens, i)
            end
        else 
            i, node = parse_norg(match(token), tokens, i)
        end
        if node isa Vector{AST.Node}
            append!(children, node)
            last_token = prevind(tokens, i)
        elseif !isnothing(node)
            push!(children, node)
            last_token = token
        end
    end
    i, AST.Node(children, AST.ParagraphSegment())
end

function parse_norg(::Type{T}, tokens, i) where T<:AST.AttachedModifier
    children = AST.Node[]
    opening_token = tokens[i]
    i = nextind(tokens, i)
    last_token = opening_token
    # @info "new modifier" opening_token i
    while i <= lastindex(tokens)
        token = tokens[i]
        # @info "attachedmodifier" i token
        if token isa Token{Tokens.LineEnding}
            break
        end
        if is_attached_modifier_delimiter(token)
            next_i = nextind(tokens, i)
            next_token = get(tokens, next_i, nothing)
            # @info "decision time" last_token token next_token i
            if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
                i, node = parse_norg(match(token), tokens, i)
            elseif !(last_token isa Token{Tokens.Whitespace}) && next_token isa AllowedAfterAttachedModifier
                # @info "I may be a quitter"
                if value(token) != value(opening_token)
                    i, node = parse_norg(AST.Word, tokens, i)
                else
                    # @info " I am a quitter"
                    i = nextind(tokens, i)
                    last_token = token
                    break
                end
            else
                i, node = parse_norg(AST.Word, tokens, i)
            end
        else 
            i, node = parse_norg(match(token), tokens, i)
        end
        if node isa Vector{AST.Node}
            append!(children, node)
            last_token = prevind(tokens, i)
        elseif !isnothing(node)
            push!(children, node)
            last_token = token
        end
    end
    if value(last_token) != value(opening_token) # we've been tricked in thincking we were in a modifier.
        pushfirst!(children, AST.Node(AST.Word(value(opening_token))))
        i, children
    elseif isempty(children)
        i, nothing
    else
        i, AST.Node(children, T())
    end
end

function parse_norg(::Type{AST.InlineCode}, tokens, i)
    children = AST.Node[]
    opening_token = tokens[i]
    i = nextind(tokens, i)
    last_token = opening_token
    # @info "new modifier" opening_token i
    while i <= lastindex(tokens)
        token = tokens[i]
        # @info "attachedmodifier" i token
        if token isa Token{Tokens.LineEnding}
            break
        end
        if token isa Token{Tokens.BackApostrophe}
            next_i = nextind(tokens, i)
            next_token = get(tokens, next_i, nothing)
            # questionnable : what do we do for nested inline codes ?
            if last_token isa AllowedBeforeAttachedModifierOpening && !(next_token isa ForbiddenAfterAttachedModifierOpening)
                i, node = parse_norg(match(token), tokens, i)
            elseif !(last_token isa Token{Tokens.Whitespace}) && next_token isa AllowedAfterAttachedModifier
                i = nextind(tokens, i)
                last_token = token
                break
            else
                i, node = parse_norg(AST.Word, tokens, i)
            end
        elseif token isa Token{Tokens.BackSlash}
            i, node = parse_norg(match(token), tokens, i)
        else 
            i, node = parse_norg(AST.Word, tokens, i)
        end
        if !isnothing(node)
            push!(children, node)
        end
        last_token = token
    end
    if !(value(last_token) == value(opening_token))
        @warn "Unmatched attached modifier" opening_token
    end
    if isempty(children)
        i, nothing
    else
        i, AST.Node(children, AST.InlineCode())
    end
end


parse_norg(::Type{AST.Escape}, tokens, i) = begin
    next_i = nextind(tokens, i)
    if get(tokens, next_i, nothing) isa Union{Token{Tokens.Word}, Nothing}
        next_i, nothing
    else
        nextind(tokens, next_i), AST.Node(AST.Escape(value(tokens[next_i])))
    end
end

parse_norg(::Type{AST.Word}, tokens, i) = nextind(tokens, i), AST.Node(AST.Word(value(tokens[i])))
    
export parse_norg
end
