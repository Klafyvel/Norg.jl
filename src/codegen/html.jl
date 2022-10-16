module HTMLCodegen
using AbstractTrees
using Hyperscript
using ..AST
import ..CodegenTarget
import ..codegen

struct HTMLTarget <: CodegenTarget end

function idify(text)
    words = map(lowercase, split(text, r"\W+"))
    join(filter(!isempty, words), '-')
end
textify(node::AST.Node{AST.Word}) = node.data.value
textify(node::AST.Node{AST.Escape}) = node.data.value
textify(node::AST.Node) = join(textify.(children(node)))

function codegen(t::HTMLTarget, node::AST.Node{AST.NorgDocument})
    m("div", class = "norg", [codegen(t, c) for c in children(node)])
end

function codegen(t::HTMLTarget, node::AST.Node{AST.Paragraph})
    res = []
    for c in children(node)
        append!(res, codegen(t, c))
        push!(res, " ")
    end
    if !isempty(res)
        pop!(res) # remove last space
    end
    m("p", res)
end

function codegen(t::HTMLTarget, node::AST.Node{AST.ParagraphSegment})
    res = []
    for c in children(node)
        push!(res, codegen(t, c))
    end
    res
end

html_node(::AST.Node{AST.Bold}) = "b"
html_node(::AST.Node{AST.Italic}) = "i"
html_node(::AST.Node{AST.Underline}) = "ins"
html_node(::AST.Node{AST.Strikethrough}) = "del"
html_node(::AST.Node{AST.Spoiler}) = "span"
html_node(::AST.Node{AST.Superscript}) = "sup"
html_node(::AST.Node{AST.Subscript}) = "sub"
html_node(::AST.Node{AST.InlineCode}) = "code"

html_class(::AST.Node{AST.Bold}) = []
html_class(::AST.Node{AST.Italic}) = []
html_class(::AST.Node{AST.Underline}) = []
html_class(::AST.Node{AST.Strikethrough}) = []
html_class(::AST.Node{AST.Spoiler}) = ["spoiler"]
html_class(::AST.Node{AST.Superscript}) = []
html_class(::AST.Node{AST.Subscript}) = []
html_class(::AST.Node{AST.InlineCode}) = []

function codegen(t::HTMLTarget, node::AST.Node{<:AST.AttachedModifier})
    res = []
    for c in children(node)
        push!(res, codegen(t, c))
    end
    class = html_class(node)
    if isempty(class)
        m(html_node(node), res)
    else
        m(html_node(node), class = join(html_class(node), " "), res)
    end
end

codegen(::HTMLTarget, node::AST.Node{AST.Word}) = node.data.value
codegen(::HTMLTarget, node::AST.Node{AST.Escape}) = node.data.value

function codegen(t::HTMLTarget, node::AST.Node{AST.Link})
    target = codegen(t, first(node.children))
    if length(node.children) > 1
        text = codegen(t, last(node.children))
    else
        text = codegen(t, first(node.children))
    end
    m("a", href = target, text)
end

function codegen(::HTMLTarget, node::AST.Node{AST.URLLocation})
    node.data.target
end

function codegen(::HTMLTarget, node::AST.Node{AST.LineNumberLocation})
    # Who are you, people who link to line location ?
    "#l-$(node.data.target)"
end

function codegen(::HTMLTarget, node::AST.Node{AST.DetachedModifierLocation})
    level = "h" * string(min(node.data.targetlevel, 6))
    title = node.data.target
    "#" * idify(level * " " * title)
end

function codegen(::HTMLTarget, ::AST.Node{AST.MagicLocation})
    # Unsupported for now. Later there will be a pass through the AST to change
    # any node of this type to a DetachedModifierLocation
    ""
end

function codegen(t::HTMLTarget, node::AST.Node{AST.FileLinkableLocation})
    start = if node.data.use_neorg_root
        "/" 
    else
        ""
    end
    subtarget = if isnothing(node.data.subtarget)
        ""
    else
        "#" * codegen(t, node.data.subtarget)
    end
    start * node.data.target * subtarget
end

function codegen(t::HTMLTarget, node::AST.Node{AST.FileLocation})
    start = if node.data.use_neorg_root
        "/" 
    else
        ""
    end
    subtarget = if isnothing(node.data.subtarget)
        ""
    else
        "#" * codegen(t, node.data.subtarget)
    end
    start * node.data.target * subtarget
end

function codegen(t::HTMLTarget, node::AST.Node{AST.LinkDescription})
    res = []
    for c in children(node)
        push!(res, codegen(t, c))
    end
    res
end

function codegen(t::HTMLTarget, node::AST.Node{AST.Anchor})
    text = codegen(t, first(node.children))
    target = if node.data.has_definition 
        codegen(t, last(node.children))
    else
        "#"
    end
    m("a", href = target, text)
end

function codegen(t::HTMLTarget, node::AST.Node{AST.Heading{T}}) where {T}
    level = "h" * string(min(AST.headinglevel(node.data), 6))
    title = textify(node.data.title)
    id_title = idify(level * " " * title)
    heading = m(level, id=id_title, codegen(t, node.data.title))
    heading_content = codegen.(Ref(t), children(node))
    id_section = idify("section " * id_title)
    m("section", id=id_section, [heading, heading_content...])
end

codegen(::HTMLTarget, ::AST.Node{AST.StrongDelimitingModifier}) = []
codegen(::HTMLTarget, ::AST.Node{AST.WeakDelimitingModifier}) = []
codegen(::HTMLTarget, ::AST.Node{AST.HorizontalRule}) = m("hr")

function codegen(t::HTMLTarget, node::AST.Node{AST.UnorderedList{T}}) where {T}
    res = []
    for c in children(node)
        push!(res, m("li", codegen(t, c)))
    end
    m("ul", res)
end

function codegen(t::HTMLTarget, node::AST.Node{AST.OrderedList{T}}) where {T}
    res = []
    for c in children(node)
        push!(res, m("li", codegen(t, c)))
    end
    m("ol", res)
end

function codegen(t::HTMLTarget, node::AST.Node{AST.Quote{T}}) where {T}
    m("blockquote", codegen.(Ref(t), children(node)))
end

function codegen(::HTMLTarget, node::AST.Node{AST.Verbatim})
    # cowardly ignore any verbatim that is not code
    if node.data.tag != "code"
        return []
    end
    language = if isempty(node.data.parameters)
        "language-plaintext"
    else
        "language-" * first(node.data.parameters)
    end
    m("pre", m("code", class=language,
        first(children(node)).data.value
    ))
end

export HTMLTarget

end
