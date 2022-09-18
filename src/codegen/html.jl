module HTMLCodegen
using AbstractTrees
using Hyperscript
using ..AST
import ..CodegenTarget
import ..codegen

struct HTMLTarget <: CodegenTarget end
function codegen(t::HTMLTarget, node::AST.Node{AST.NorgDocument})
    m("div", class = "norg", [codegen(t, c) for c in children(node)])
end

function codegen(t::HTMLTarget, node::AST.Node{AST.Paragraph})
    res = []
    for c in children(node)
        append!(res, codegen(t, c))
        push!(res, m("br"))
    end
    if !isempty(res)
        pop!(res) # remove last <br>
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

export HTMLTarget

end
