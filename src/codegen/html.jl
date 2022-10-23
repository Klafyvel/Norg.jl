module HTMLCodegen
using AbstractTrees
using Hyperscript
using ..AST
using ..Strategies
using ..Kinds
import ..CodegenTarget
import ..codegen

struct HTMLTarget <: CodegenTarget end

function idify(text)
    words = map(lowercase, split(text, r"\W+"))
    join(filter(!isempty, words), '-')
end

function codegen(t::HTMLTarget, ast::AST.NorgDocument)
    m("div", class = "norg", [codegen(t, ast, c) for c in children(ast)])
end

function codegen(t::HTMLTarget, ast::AST.NorgDocument, node::AST.Node)
    if kind(node) == K"Paragraph"
        codegen(t, Paragraph(), ast, node)        
    elseif kind(node) == K"ParagraphSegment"
        codegen(t, ParagraphSegment(), ast, node)
    elseif kind(node) == K"Bold"
        codegen(t, Bold(), ast, node)
    elseif kind(node) == K"Italic"
        codegen(t, Italic(), ast, node)
    elseif kind(node) == K"Underline"
        codegen(t, Underline(), ast, node)
    elseif kind(node) == K"Strikethrough"
        codegen(t, Strikethrough(), ast, node)
    elseif kind(node) == K"Spoiler"
        codegen(t, Spoiler(), ast, node)
    elseif kind(node) == K"Superscript"
        codegen(t, Superscript(), ast, node)
    elseif kind(node) == K"Subscript"
        codegen(t, Subscript(), ast, node)
    elseif kind(node) == K"InlineCode"
        codegen(t, InlineCode(), ast, node)
    elseif kind(node) == K"WordNode"
        codegen(t, Word(), ast, node)
    elseif kind(node) == K"Escape"
        codegen(t, Escape(), ast, node)
    elseif kind(node) == K"Link"
        codegen(t, Link(), ast, node)
    elseif kind(node) == K"URLLocation"
        codegen(t, URLLocation(), ast, node)
    elseif kind(node) == K"LineNumberLocation"
        codegen(t, LineNumberLocation(), ast, node)
    elseif kind(node) == K"DetachedModifierLocation"
        codegen(t, DetachedModifierLocation(), ast, node)
    elseif kind(node) == K"MagicLocation"
        codegen(t, MagicLocation(), ast, node)
    elseif kind(node) == K"FileLocation"
        codegen(t, FileLocation(), ast, node)
    elseif kind(node) == K"NorgFileLocation"
        codegen(t, NorgFileLocation(), ast, node)
    elseif kind(node) == K"LinkDescription"
        codegen(t, LinkDescription(), ast, node)
    elseif kind(node) == K"Anchor"
        codegen(t, Anchor(), ast, node)
    elseif is_heading(node)
        codegen(t, Heading(), ast, node)
    elseif kind(node) == K"StrongDelimitingModifier"
        codegen(t, StrongDelimiter(), ast, node)
    elseif kind(node) == K"WeakDelimitingModifier"
        codegen(t, WeakDelimiter(), ast, node)
    elseif kind(node) == K"HorizontalRule"
        codegen(t, HorizontalRule(), ast, node)
    elseif is_unordered_list(node)
        codegen(t, UnorderedList(), ast, node)
    elseif is_ordered_list(node)
        codegen(t, OrderedList(), ast, node)
    elseif is_quote(node)
        codegen(t, Quote(), ast, node)
    elseif kind(node) == K"NestableItem"
        codegen(t, NestableItem(), ast, node)
    elseif kind(node) == K"Verbatim"
        codegen(t, Verbatim(), ast, node)
    else
        error("HTML codegen got unhandled node type: $(kind(node))")
    end
end

function codegen(t::HTMLTarget, ::Paragraph, ast, node)
    res = []
    for c in children(node)
        append!(res, codegen(t, ast, c))
        push!(res, " ")
    end
    if !isempty(res)
        pop!(res) # remove last space
    end
    m("p", res)
end

function codegen(t::HTMLTarget, ::ParagraphSegment, ast, node)
    res = []
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    res
end

html_node(::Bold) = "b"
html_node(::Italic) = "i"
html_node(::Underline) = "ins"
html_node(::Strikethrough) = "del"
html_node(::Spoiler) = "span"
html_node(::Superscript) = "sup"
html_node(::Subscript) = "sub"
html_node(::InlineCode) = "code"

html_class(::Bold) = []
html_class(::Italic) = []
html_class(::Underline) = []
html_class(::Strikethrough) = []
html_class(::Spoiler) = ["spoiler"]
html_class(::Superscript) = []
html_class(::Subscript) = []
html_class(::InlineCode) = []

function codegen(t::HTMLTarget, s::T, ast, node) where {T<:AttachedModifierStrategy}
    res = []
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    class = html_class(s)
    if isempty(class)
        m(html_node(s), res)
    else
        m(html_node(s), class = join(html_class(s), " "), res)
    end
end

function codegen(t::HTMLTarget, ::Word, ast, node)
    if is_leaf(node)
        AST.litteral(ast, node)
    else
        join(codegen(t, Word(), ast, c) for c in children(node))
    end
end
codegen(t::HTMLTarget, ::Escape, ast, node) = codegen(t, Word(), ast, node)

function codegen(t::HTMLTarget, ::Link, ast, node)
    target = codegen(t, ast, first(node.children))
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        text = codegen(t, ast, children(first(children(node)))[2])
    else
        text = codegen(t, ast, first(node.children))
    end
    m("a", href = target, text)
end

function codegen(t::HTMLTarget, ::URLLocation, ast, node)
    codegen(t, Word(), ast, first(children(node)))
end

function codegen(t::HTMLTarget, ::LineNumberLocation, ast, node)
    # Who are you, people who link to line location ?
    "#l-$(codegen(t, Word(), ast, first(children(node))))"
end

function codegen(t::HTMLTarget, ::DetachedModifierLocation, ast, node)
    level_num = AST.heading_level(first(children(node)))
    level = "h" * string(level_num)
    title = codegen(t, Word(), ast, last(children(node)))
    "#" * idify(level * " " * title)
end

function codegen(::HTMLTarget, ::MagicLocation, ast, node)
    # Unsupported for now. Later there will be a pass through the AST to change
    # any node of this type to a DetachedModifierLocation
    ""
end

function codegen(t::HTMLTarget, ::FileLocation, ast, node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/" 
    else
        start = "" 
    end
    target_loc = codegen(t, Word(), ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    
    start * target_loc * subtarget_loc
end

function codegen(t::HTMLTarget, ::NorgFileLocation, ast, node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/" 
    else
        start = "" 
    end
    target_loc = codegen(t, Word(), ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    
    start * target_loc * subtarget_loc
end

codegen(t::HTMLTarget, ::LinkDescription, ast, node) = codegen(t, ast, first(children(node)))

function codegen(t::HTMLTarget, ::Anchor, ast, node)
    text = codegen(t, ast, first(node.children))
    if length(children(node)) == 1
        target = "#"
    else
        target = codegen(t, ast, last(children(node)))
    end
    m("a", href = target, text)
end

function codegen(t::HTMLTarget, ::Heading, ast, node)
    level_num = AST.heading_level(node)
    level = "h" * string(level_num)
    heading_title, content... = children(node)
    title = codegen(t, Word(), ast, heading_title)
    id_title = idify(level * " " * title)
    heading = m(level, id=id_title, codegen(t, ast, heading_title))
    heading_content = [codegen(t, ast, c, ) for c in content]
    id_section = idify("section " * id_title)
    m("section", id=id_section, [heading, heading_content...])
end

codegen(::HTMLTarget, ::StrongDelimiter, ast, node) = []
codegen(::HTMLTarget, ::WeakDelimiter, ast, node) = []
codegen(::HTMLTarget, ::HorizontalRule, ast, node) = m("hr")

function codegen(t::HTMLTarget, ::UnorderedList, ast, node)
    m("ul", [codegen(t, ast, c) for c in children(node)])
end

function codegen(t::HTMLTarget, ::OrderedList, ast, node)
    m("ol", [codegen(t, ast, c) for c in children(node)])
end

function codegen(t::HTMLTarget, ::NestableItem, ast, node)
    m("li", [codegen(t, ast, c) for c in children(node)])
end

function codegen(t::HTMLTarget, ::Quote, ast, node)
    # <blockquote> does not have an 'item' notion, so we have to short-circuit
    # that.
    res = []
    for c in children(node)
        append!(res, codegen.(Ref(t), Ref(ast), children(c)))
    end
    m("blockquote", res)
end

function codegen(::HTMLTarget, ::Verbatim, ast, node)
    # cowardly ignore any verbatim that is not code
    tag, others... = children(node)
    if litteral(ast, tag) != "code"
        return []
    end
    language = if length(others) == 1
        "language-plaintext"
    else
        if kind(first(others)) == K"VerbatimParameter"
            lang = litteral(ast, first(others))
        else
            lang = litteral(ast, others[2])
        end
        "language-" * lang
    end
    m("pre", m("code", class=language, litteral(ast, last(others))))
end

export HTMLTarget

end
