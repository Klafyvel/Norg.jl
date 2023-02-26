"""
Pandoc AST code generation. The best reference of Pandoc's AST I could find is
[here](https://hackage.haskell.org/package/pandoc-types-1.22.2.1/docs/Text-Pandoc-Definition.html)

The code generated consists in `OrderedDict`s from [OrderedCollections.jl](https://github.com/JuliaCollections/OrderedCollections.jl) that
follow the Pandoc JSON AST API. You can then export using *e.g.* [JSON.jl](https://github.com/JuliaIO/JSON.jl).
"""
module JSONCodegen
using Base: CacheHeaderIncludes
using OrderedCollections
using AbstractTrees

using ..AST
using ..Strategies
using ..Kinds
using ..Tokens
import ..CodegenTarget
import ..codegen
import ..textify
import ..idify

"""
JSON target to feed [`codegen`](@ref).
"""
struct JSONTarget <: CodegenTarget end

function codegen_children(t::JSONTarget, ast::AST.NorgDocument, node::Node)
    res = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(res, r)
        end
    end
    res
end

function codegen(t::JSONTarget, ast::AST.NorgDocument)
    OrderedDict([
        "pandoc-api-version" => [1, 23]
        "meta" => OrderedDict{String, String}()
        "blocks" => codegen_children(t, ast, ast.root)
    ])
end

function codegen(t::JSONTarget, ::Paragraph, ast::NorgDocument, node::Node)
    res = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            if r isa Vector
                append!(res, r)
            else
                push!(res, r)
            end
            push!(res, OrderedDict{String, Any}("t" => "SoftBreak"))
        end
    end
    if !isempty(res)
        pop!(res) # remove last softbreak
    end
    OrderedDict([
        "t" => "Para"
        "c" => res
    ])
end

codegen(t::JSONTarget, ::ParagraphSegment, ast::NorgDocument, node::Node) = codegen_children(t, ast, node)

pandoc_t(::Union{FreeFormBold, Bold}) = "Strong"
pandoc_t(::Union{FreeFormItalic, Italic}) = "Emph"
pandoc_t(::Union{FreeFormUnderline, Underline}) = "Underline"
pandoc_t(::Union{FreeFormStrikethrough, Strikethrough}) = "Strikeout"
pandoc_t(::Union{FreeFormSpoiler, Spoiler}) = "Span"
pandoc_t(::Union{FreeFormSuperscript, Superscript}) = "Superscript"
pandoc_t(::Union{FreeFormSubscript, Subscript}) = "Subscript"
pandoc_t(::Union{FreeFormInlineCode, InlineCode}) = "Code"

pandoc_attr(::Union{FreeFormBold, Bold}) = []
pandoc_attr(::Union{FreeFormItalic, Italic}) = []
pandoc_attr(::Union{FreeFormUnderline, Underline}) = []
pandoc_attr(::Union{FreeFormStrikethrough, Strikethrough}) = []
pandoc_attr(::Union{FreeFormSpoiler, Spoiler}) = ["", ["spoiler"], []]
pandoc_attr(::Union{FreeFormSuperscript, Superscript}) = []
pandoc_attr(::Union{FreeFormSubscript, Subscript}) = []
pandoc_attr(::Union{FreeFormInlineCode, InlineCode}) = ["", [], []]

function codegen(t::JSONTarget, s::T, ast::NorgDocument, node::Node) where {T<:AttachedModifierStrategy}
    res = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            append!(res, r)
            push!(res, OrderedDict{String, Any}("t" => "SoftBreak"))
        end
    end
    attr = pandoc_attr(s)
    if isempty(attr)
        OrderedDict([
            "t"=>pandoc_t(s)
            "c" => res
        ])
    else
        OrderedDict([
            "t"=>pandoc_t(s)
            "c" => [attr, res]
        ])
    end
end

function codegen(::JSONTarget, ::Union{InlineMath, FreeFormInlineMath}, ast::NorgDocument, node::Node) 
    OrderedDict([
        "t"=>"Math"
        "c" => [OrderedDict(["t"=>"InlineMath"]), textify(ast, node)]
    ])
end

function codegen(::JSONTarget, ::Union{Variable, FreeFormVariable}, ::NorgDocument, ::Node) 
    []
end

function codegen(::JSONTarget, ::Union{NullModifier, FreeFormNullModifier}, ::NorgDocument, ::Node) 
    []
end

function codegen(t::JSONTarget, s::Union{InlineCode, FreeFormInlineCode}, ast::NorgDocument, node::Node)
    OrderedDict([
        "t"=>pandoc_t(s)
        "c" => [pandoc_attr(s), textify(ast, node)]
    ])
end

function codegen(t::JSONTarget, ::Word, ast::NorgDocument, node::Node)
    if is_leaf(node) && (AST.stop(node) - AST.start(node) > 0)
        OrderedDict([
            "t"=>"Str"
            "c"=>AST.litteral(ast, node)
        ])
    elseif is_leaf(node)
        token = first(ast.tokens[AST.start(node):AST.stop(node)])
        if Tokens.is_whitespace(token)
            OrderedDict([
                "t"=>"Space"
            ])
        else
            OrderedDict([
                "t"=>"Str"
                "c"=>AST.litteral(ast, node)
            ])
        end
    else
        [codegen(t, Word(), ast, c) for c in children(node)]
    end
end
codegen(t::JSONTarget, ::Escape, ast, node) = codegen(t, ast, first(children(node)))

function codegen(t::JSONTarget, ::Link, ast::NorgDocument, node::Node)
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        text = codegen(t, ast, children(first(children(node)))[2])
    elseif kind(first(node.children)) == K"MagicLocation"
        text = codegen(t, ast, children(first(children(node)))[1])
    elseif kind(first(node.children)) == K"WikiLocation"
        text = codegen(t, ast, children(first(children(node)))[1])
    elseif kind(first(node.children)) == K"TimestampLocation"
        text = textify(ast, first(node.children))
    else
        text = [OrderedDict(["t"=>"Str", "c"=>codegen(t, ast, first(node.children))])]
    end
    if kind(first(node.children)) == K"TimestampLocation"
        OrderedDict([
            "t"=>"Str"
            "c"=>text
            ])
    else
        target = codegen(t, ast, first(node.children))
        OrderedDict([
            "t"=>"Link"
            "c"=>[
                ["", Any[], Any[]],
                text,
                [target, ""]
            ]
        ])
    end
end

codegen(::JSONTarget, ::URLLocation, ast, node) = textify(ast, node)

function codegen(::JSONTarget, ::LineNumberLocation, ast::NorgDocument, node::Node)
    # Who are you, people who link to line location ?
    "#l-$(textify(ast, node))"
end

function codegen(t::JSONTarget, ::DetachedModifierLocation, ast::NorgDocument, node::Node)
    kindoftarget = kind(first(children(node)))
    title = textify(ast, last(children(node)))
    if AST.is_heading(kindoftarget)
        level_num = AST.heading_level(first(children(node)))
        level = "h" * string(level_num)
        "#" * idify(level * " " * title)
    elseif kindoftarget == K"Definition"
        "#" * "def_" * idify(title)
    elseif kindoftarget == K"Footnote"
        "#" * "fn_" * idify(title)
    else
        error("JSON code generation received an unknown Detached Modifier location: $kindoftarget")
    end
end

function codegen(::JSONTarget, ::MagicLocation, ast::NorgDocument, node::Node)
    key = textify(ast, node)
    if haskey(ast.targets, key)
        kindoftarget, targetnoderef = ast.targets[key]
        title = textify(ast, first(children(targetnoderef[])))
        if AST.is_heading(kindoftarget)
            level_num = AST.heading_level(kindoftarget)
            level = "h" * string(level_num)
            "#" * idify(level * " " * title)
        elseif kindoftarget == K"Definition"
            "#" * "def_" * idify(title)
        elseif kindoftarget == K"Footnote"
            "#" * "fn_" * idify(title)
        else
            error("JSON code generation received an unknown Detached Modifier location: $kindoftarget")
        end
    else
        "" 
    end
end

function codegen(t::JSONTarget, ::FileLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/" 
    else
        start = "" 
    end
    target_loc = textify(ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    
    start * target_loc * subtarget_loc
end

function codegen(t::JSONTarget, ::NorgFileLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/" 
    else
        start = "" 
    end
    target_loc = textify(ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    
    start * target_loc * subtarget_loc
end

function codegen(t::JSONTarget, ::WikiLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    target_loc = textify(ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    "/" * target_loc * subtarget_loc
end

codegen(::JSONTarget, ::TimestampLocation, ast::NorgDocument, node::Node) = textify(ast, node)

codegen(t::JSONTarget, ::LinkDescription, ast::NorgDocument, node::Node) = collect(Iterators.flatten(codegen_children(t, ast, node)))

function codegen(t::JSONTarget, ::Anchor, ast::NorgDocument, node::Node)
    text = codegen(t, ast, first(node.children))
    if length(children(node)) == 1
        target = "#"
    else
        target = codegen(t, ast, last(children(node)))
    end
    OrderedDict([
        "t"=>"Link"
        "c"=>[
            ["", Any[], Any[]],
            text,
            [target, ""]
        ]
    ])
end

function codegen(t::JSONTarget, ::InlineLinkTarget, ast::NorgDocument, node::Node)
    text = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            append!(text, r)
            push!(text, " ")
        end
    end
    if !isempty(text)
        pop!(text) # remove last space
    end
    id = idify(join(textify(ast, node)))
    OrderedDict([
        "t"=>"Span"
        "c"=>[
            [id, Any[], Any[]],
            text
        ]
    ])
end

function codegen(t::JSONTarget, ::Heading, ast::NorgDocument, node::Node)
    level_num = AST.heading_level(node)
    level = "h" * string(level_num)
    c = children(node)
    heading_title_node = first(c)
    if AST.is_detached_modifier_extension(kind(heading_title_node))
        c = c[2:end]
        heading_title_node = first(c)
        _, heading_title, heading_content... = codegen_children(t, ast, node)
    else
        heading_title, heading_content... = codegen_children(t, ast, node)
    end
    title = textify(ast, heading_title_node)
    id_title = idify(level * " " * title)
    heading = OrderedDict([
        "t"=>"Header"
        "c"=>[level_num, [id_title, [], []], heading_title]
        ])
    id_section = idify("section " * id_title)
    OrderedDict([
        "t"=>"Div"
        "c"=>[[id_section, [], []], [heading, heading_content...]]
        ])
end

codegen(::JSONTarget, ::StrongDelimiter, ast::NorgDocument, node::Node) = OrderedDict()
codegen(::JSONTarget, ::WeakDelimiter, ast::NorgDocument, node::Node) = OrderedDict()
codegen(::JSONTarget, ::HorizontalRule, ast::NorgDocument, node::Node) = OrderedDict(["t"=>"HorizontalRule", "c"=>[]])

function codegen_nestable_children(t::JSONTarget, ast::NorgDocument, node::Node)
    res = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            if kind(c) == K"NestableItem"
                push!(res, r)
            else
                push!(res, [r])
            end
        end
    end
    res
end

function codegen(t::JSONTarget, ::UnorderedList, ast::NorgDocument, node::Node)
    OrderedDict([
        "t"=>"BulletList"
        "c"=>codegen_nestable_children(t, ast, node)
    ])
end

function codegen(t::JSONTarget, ::OrderedList, ast::NorgDocument, node::Node)
    OrderedDict([
        "t"=>"OrderedList"
        "c"=>[
            [1, OrderedDict(["t"=>"Decimal"]), OrderedDict(["t"=>"Period"])],
            codegen_nestable_children(t, ast, node)
        ]
    ])
end

function codegen(t::JSONTarget, ::NestableItem, ast::NorgDocument, node::Node)
    res = []
    for c in children(node)
        if kind(c) ∉ KSet"TimestampExtension PriorityExtension DueDateExtension StartDateExtension"
            r = codegen(t, ast, c)

            if r isa Vector
                append!(res, r)
            elseif !isempty(r)
                push!(res, r)
            end
        end
    end
    res
end

function codegen(t::JSONTarget, ::Quote, ast::NorgDocument, node::Node)
    # <blockquote> does not have an 'item' notion, so we have to short-circuit
    # that.
    res = []
    for c in children(node)
        append!(res, filter(!isempty, codegen.(Ref(t), Ref(ast), children(c)))|>collect)
    end
    OrderedDict([
        "t"=>"BlockQuote"
        "c"=>res
    ])
end

function codegen(::JSONTarget, ::Verbatim, ast::NorgDocument, node::Node)
    # cowardly ignore any verbatim that is not code
    tag, others... = children(node)
    if litteral(ast, tag) != "code"
        return OrderedDict()
    end
    if length(others) == 1
        OrderedDict([
            "t"=>"CodeBlock"
            "c"=>[["", [], []], textify(ast, last(others))]
        ])
    else
        language = if kind(first(others)) == K"TagParameter"
            litteral(ast, first(others))
        else
            litteral(ast, others[2])
        end
        OrderedDict([
            "t"=>"CodeBlock"
            "c"=>[["", [language], []], textify(ast, last(others))]
        ])
    end
end

function codegen(::JSONTarget, ::TodoExtension, ast::NorgDocument, node::Node)
    status = first(children(node))
    checked = kind(status) == K"StatusDone"
    if checked
        s = "☑"
    else
        s = "☐"
    end
    OrderedDict([
    "t"=>"Plain"
    "c"=>[OrderedDict([
        "t"=>"Str"
        "c"=>s
        ])]
    ])
end

function codegen(t::JSONTarget, c::Union{WeakCarryoverTag, StrongCarryoverTag}, ast::NorgDocument, node::Node)
    content = codegen(t, ast, last(children(node)))
    label = textify(ast, first(children(node)))
    # TODO: there's most likely some room for improvement here, as some contents
    # already have a mechanism for attributes, so the Div is not needed.
    attr = ["", [], []]
    if length(children(node)) <= 2
        attr[2] = [label]
    elseif length(children(node)) == 3
        attr[3] = [[label, textify(ast, children(node)[2])]]
    else
        attr[2] = [join(textify.(Ref(ast), children(node)[1:end-1]), "-")]
    end

    t = if kind(node) == K"WeakCarryoverTag" && kind(last(children(node)))==K"ParagraphSegment"
        "Span"
    else
        "Div"
    end
    if !(content isa Vector)
        content = [content]
    end
    OrderedDict([
        "t"=>t,
        "c"=>[attr, content]
    ])
end

function codegen(t::JSONTarget, ::Definition, ast::NorgDocument, node::Node)
    items = children(node)
    OrderedDict([
        "t"=>"DefinitionList"
        "c"=>map(items) do item
            term, def... = children(item)
            term_id = "def_" * idify(textify(ast, term))
            term_node = OrderedDict([
                "t"=>"Span"
                "c"=>[
                    (term_id, [], []),
                    codegen(t, ast, term)
                ]
            ])
            def_node = codegen.(Ref(t), Ref(ast), def)
            ([term_node], [def_node])
        end
    ])
end

function codegen(t::JSONTarget, ::Footnote, ast::NorgDocument, node::Node)
    # Return nothing, pandoc expects footnotes to be defined where they are called.
    []
end

function codegen(t::JSONTarget, ::Slide, ast::NorgDocument, node::Node)
    codegen(t, ast, first(children(node)))
end

function codegen(t::JSONTarget, ::IndentSegment, ast::NorgDocument, node::Node)
    codegen_children(t, ast, node)
end

export JSONTarget

end
