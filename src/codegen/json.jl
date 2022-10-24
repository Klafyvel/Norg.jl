"""
Pandoc AST code generation. The best reference of Pandoc's AST I could find is
[here](https://hackage.haskell.org/package/pandoc-types-1.22.2.1/docs/Text-Pandoc-Definition.html)
"""
module JSONCodegen
using Base: CacheHeaderIncludes
import JSON
using DataStructures
using AbstractTrees

using ..AST
using ..Strategies
using ..Kinds
using ..Tokens
import ..CodegenTarget
import ..codegen
import ..textify
import ..idify

struct JSONTarget <: CodegenTarget end

function codegen(t::JSONTarget, ast::AST.NorgDocument)
    OrderedDict([
        "pandoc-api-version" => [1, 22, 2, 1]
        "meta" => OrderedDict{String, String}()
        "blocks" => [
            codegen(t, ast, c) for c in children(ast)
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
        push!(res, codegen(t, ast, c))
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
    target = codegen(t, ast, first(node.children))
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        text = codegen(t, ast, children(first(children(node)))[2])
    elseif kind(first(node.children)) == K"MagicLocation"
        text = codegen(t, ast, children(first(children(node)))[1])
    else
        text = [OrderedDict(["t"=>"Str", "c"=>codegen(t, ast, first(node.children))])]
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

codegen(::JSONTarget, ::URLLocation, ast, node) = textify(ast, node)

function codegen(::JSONTarget, ::LineNumberLocation, ast, node)
    # Who are you, people who link to line location ?
    "#l-$(textify(ast, node))"
end

function codegen(t::JSONTarget, ::DetachedModifierLocation, ast, node)
    level_num = AST.heading_level(first(children(node)))
    level = "h" * string(level_num)
    title = textify(ast, node)
    "#" * idify(level * " " * title)
end

function codegen(::JSONTarget, ::MagicLocation, ast, node)
    # Unsupported for now. Later there will be a pass through the AST to change
    # any node of this type to a DetachedModifierLocation
    ""
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

codegen(t::JSONTarget, ::LinkDescription, ast, node) = codegen(t, ast, first(children(node)))

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
        language = if kind(first(others)) == K"VerbatimParameter"
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


export JSONTarget

end
