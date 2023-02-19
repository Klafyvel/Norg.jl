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

function codegen(t::JSONTarget, ast::AST.NorgDocument)
    OrderedDict([
        "pandoc-api-version" => [1, 22, 2, 1]
        "meta" => OrderedDict{String, String}()
        "blocks" => [
            codegen(t, ast, c) for c in children(ast.root)
        ]
    ])
end

function codegen(t::JSONTarget, ::Paragraph, ast, node)
    res = []
    for c in children(node)
        append!(res, codegen(t, ast, c))
        push!(res, OrderedDict{String, Any}("t" => "SoftBreak"))
    end
    if !isempty(res)
        pop!(res) # remove last softbreak
    end
    OrderedDict([
        "t" => "Para"
        "c" => res
    ])
end

function codegen(t::JSONTarget, ::ParagraphSegment, ast, node)
    res = []
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    res
end

pandoc_t(::Bold) = "Strong"
pandoc_t(::Italic) = "Emph"
pandoc_t(::Underline) = "Underline"
pandoc_t(::Strikethrough) = "Strikeout"
pandoc_t(::Spoiler) = "Span"
pandoc_t(::Superscript) = "Superscript"
pandoc_t(::Subscript) = "Subscript"
pandoc_t(::InlineCode) = "Code"

pandoc_attr(::Bold) = []
pandoc_attr(::Italic) = []
pandoc_attr(::Underline) = []
pandoc_attr(::Strikethrough) = []
pandoc_attr(::Spoiler) = ["", ["spoiler"], []]
pandoc_attr(::Superscript) = []
pandoc_attr(::Subscript) = []
pandoc_attr(::InlineCode) = ["", [], []]

function codegen(t::JSONTarget, s::T, ast, node) where {T<:AttachedModifierStrategy}
    res = []
    for c in children(node)
        # each children is a paragraph segment
        append!(res, codegen(t, ast, c))
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

function codegen(t::JSONTarget, s::InlineCode, ast, node)
    OrderedDict([
        "t"=>pandoc_t(s)
        "c" => [pandoc_attr(s), textify(ast, node)]
    ])
end

function codegen(t::JSONTarget, ::Word, ast, node)
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

function codegen(t::JSONTarget, ::Link, ast, node)
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

function codegen(::JSONTarget, ::LineNumberLocation, ast, node)
    # Who are you, people who link to line location ?
    "#l-$(textify(ast, node))"
end

function codegen(t::JSONTarget, ::DetachedModifierLocation, ast, node)
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

function codegen(::JSONTarget, ::MagicLocation, ast, node)
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

function codegen(t::JSONTarget, ::FileLocation, ast, node)
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

function codegen(t::JSONTarget, ::NorgFileLocation, ast, node)
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

function codegen(t::JSONTarget, ::WikiLocation, ast, node)
    target, subtarget = children(node)
    target_loc = textify(ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    "/" * target_loc * subtarget_loc
end

codegen(::JSONTarget, ::TimestampLocation, ast, node) = textify(ast, node)

codegen(t::JSONTarget, ::LinkDescription, ast, node) = collect(Iterators.flatten([codegen(t, ast, c) for c in children(node)]))

function codegen(t::JSONTarget, ::Anchor, ast, node)
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

function codegen(t::JSONTarget, ::InlineLinkTarget, ast, node)
    text = []
    for c in children(node)
        append!(text, codegen(t, ast, c))
        push!(text, " ")
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

function codegen(t::JSONTarget, ::Heading, ast, node)
    level_num = AST.heading_level(node)
    level = "h" * string(level_num)
    heading_title, content... = children(node)
    title = textify(ast, heading_title)
    id_title = idify(level * " " * title)
    heading = OrderedDict([
        "t"=>"Header"
        "c"=>[level_num, [id_title, [], []], codegen(t, ast, heading_title)]
        ])
    heading_content = [codegen(t, ast, c) for c in content]
    id_section = idify("section " * id_title)
    OrderedDict([
        "t"=>"Div"
        "c"=>[[id_section, [], []], [heading, heading_content...]]
        ])
end

codegen(::JSONTarget, ::StrongDelimiter, ast, node) = OrderedDict(["t"=>"Null"])
codegen(::JSONTarget, ::WeakDelimiter, ast, node) = OrderedDict(["t"=>"Null"])
codegen(::JSONTarget, ::HorizontalRule, ast, node) = OrderedDict(["t"=>"HorizontalRule", "c"=>[]])

function codegen(t::JSONTarget, ::UnorderedList, ast, node)
    OrderedDict([
        "t"=>"BulletList"
        "c"=>[
            codegen(t, ast, c) for c in children(node)
        ]
    ])
end

function codegen(t::JSONTarget, ::OrderedList, ast, node)
    OrderedDict([
        "t"=>"OrderedList"
        "c"=>[
            [1, OrderedDict(["t"=>"Decimal"]), OrderedDict(["t"=>"Period"])],
            [codegen(t, ast, c) for c in children(node)]
        ]
    ])
end

function codegen(t::JSONTarget, ::NestableItem, ast, node)
    [codegen(t, ast, c) for c in children(node)]
end

function codegen(t::JSONTarget, ::Quote, ast, node)
    # <blockquote> does not have an 'item' notion, so we have to short-circuit
    # that.
    res = []
    for c in children(node)
        append!(res, codegen.(Ref(t), Ref(ast), children(c)))
    end
    OrderedDict([
        "t"=>"BlockQuote"
        "c"=>res
    ])
end

function codegen(::JSONTarget, ::Verbatim, ast, node)
    # cowardly ignore any verbatim that is not code
    tag, others... = children(node)
    if litteral(ast, tag) != "code"
        return OrderedDict(["t"=>"Null"])
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

function codegen(::JSONTarget, ::TodoExtension, ast, node)
    status = first(children(node))
    checked = kind(status) == K"StatusDone"
    if checked
        s = "☑"
    else
        s = "☐"
    end
    OrderedDict([
    "t"=>"Str"
    "c"=>s
    ])
end

function codegen(t::JSONTarget, ::Union{WeakCarryoverTag, StrongCarryoverTag}, ast, node)
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
    OrderedDict([
        "t"=>"Div"
        "c"=>[attr, content]
    ])
end

function codegen(t::JSONTarget, ::Definition, ast, node)
    items = children(node)
    OrderedDict([
        "t"=>"DefinitionList"
        "c"=>map(items) do item
            term, def... = children(item)
            term_id = "def_" * idify(textify(ast, term))
            term_node = OrderedDict([
                "t"=>"Span"
                "c"=>[
                    (term_id, [], [])
                    codegen(t, ast, term)
                ]
            ])
            def_node = codegen.(Ref(t), Ref(ast), def)
            (term_node, def_node)
        end
    ])
end

function codegen(t::JSONTarget, ::Footnote, ast, node)
    # Return nothing, pandoc expects footnotes to be defined where they are called.
    []
end

function codegen(t::JSONTarget, ::Slide, ast, node)
    codegen(t, ast, first(children(node)))
end

function codegen(t::JSONTarget, ::IndentSegment, ast, node)
    codegen.(Ref(t), Ref(ast), children(node))
end

export JSONTarget

end
