"""Norg code generation."""
module NorgCodegen
using AbstractTrees
using ..AST
using ..Strategies
using ..Kinds
import ..CodegenTarget
import ..codegen
import ..parse_norg_timestamp

struct NorgTarget{T} <: CodegenTarget
    buf::T
end
NorgTarget() = NorgTarget{IOBuffer}(IOBuffer())
Base.take!(norg::NorgTarget) = take!(norg.buf)

export NorgTarget

function codegen_chidlren_sep(t::NorgTarget, ast::NorgDocument, node::Node, sep)
    first = true
    local prev
    for c in children(node)
        if @isdefined prev
            first ? (first = false) : write(t.buf, sep)
            codegen(t, ast, prev)
        end
        prev = c
    end
    if @isdefined prev
        first ? (first = false) : write(t.buf, sep)
        codegen(t, ast, prev)
    end
    t    
end

function codegen(t::NorgTarget, ast::NorgDocument)
    codegen_chidlren_sep(t, ast, ast.root, "\n\n")
end

function codegen(t::NorgTarget, ::Paragraph, ast::NorgDocument, node::Node)
    codegen_chidlren_sep(t, ast, node, "\n")
end

function codegen(t::NorgTarget, ::ParagraphSegment, ast::NorgDocument, node::Node)
    codegen_chidlren_sep(t, ast, node, "")
end

attached_modifier(::Union{FreeFormBold,Bold}) = "*"
attached_modifier(::Union{FreeFormItalic,Italic}) = "/"
attached_modifier(::Union{FreeFormUnderline,Underline}) = "_"
attached_modifier(::Union{FreeFormStrikethrough,Strikethrough}) = "-"
attached_modifier(::Union{FreeFormSpoiler,Spoiler}) = "!"
attached_modifier(::Union{FreeFormSuperscript,Superscript}) = "^"
attached_modifier(::Union{FreeFormSubscript,Subscript}) = ","
attached_modifier(::Union{FreeFormInlineCode,InlineCode}) = "`"
attached_modifier(::Union{FreeFormNullModifier,NullModifier}) = "%"
attached_modifier(::Union{FreeFormInlineMath,InlineMath}) = "\$"
attached_modifier(::Union{FreeFormVariable,Variable}) = "&"

is_freeform(_) = false
is_freeform(::FreeFormBold) = true
is_freeform(::FreeFormItalic) = true
is_freeform(::FreeFormUnderline) = true
is_freeform(::FreeFormStrikethrough) = true
is_freeform(::FreeFormSpoiler) = true
is_freeform(::FreeFormSuperscript) = true
is_freeform(::FreeFormSubscript) = true
is_freeform(::FreeFormInlineCode) = true
is_freeform(::FreeFormNullModifier) = true
is_freeform(::FreeFormInlineMath) = true
is_freeform(::FreeFormVariable) = true

function codegen(t::NorgTarget, s::T, ast::NorgDocument, node::Node) where {T<:AttachedModifierStrategy}
    write(t.buf, attached_modifier(s))
    if is_freeform(s)
        write(t.buf, "|")        
    end
    for c in children(node)
        codegen(t, ast, c)
    end
    if is_freeform(s)
        write(t.buf, "|")        
    end
    write(t.buf, attached_modifier(s))
    t
end

function codegen(t::NorgTarget, ::Word, ast::NorgDocument, node::Node)
    write(t.buf, AST.litteral(ast, node))
    t
end

function codegen(t::NorgTarget, ::Escape, ast::NorgDocument, node::Node)
    write(t.buf, "\\")
    codegen(t, Word(), ast, first(node.children))
end

end
