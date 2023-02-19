"""
HTML code generation using [Hyperscript.jl](https://docs.juliahub.com/Hyperscript/L2xXR/0.0.4/).
"""
module HTMLCodegen
using AbstractTrees
using Hyperscript
using Dates
using ..AST
using ..Strategies
using ..Kinds
import ..CodegenTarget
import ..codegen
import ..idify
import ..textify
import ..getchildren
import ..parse_norg_timestamp

"""
Controls the position where footnotes are rendered. It can be within the lowest
heading level `i` by setting `HiFootnotes` or at the root of the document or
directly as it appears in the Norg document.
"""
@enum FootnotesLevel begin
    RootFootnotes=0
    H1Footnotes=1
    H2Footnotes=2
    H3Footnotes=3
    H4Footnotes=4
    H5Footnotes=5
    H6Footnotes=6
    InplaceFootnotes=7
end

"""
HTML target to feed [`codegen`](@ref).
"""
struct HTMLTarget <: CodegenTarget 
    footnotes_level::FootnotesLevel
end

HTMLTarget() = HTMLTarget(RootFootnotes)

function codegen(t::HTMLTarget, ast::AST.NorgDocument)
    content = [codegen(t, ast, c) for c in children(ast.root)]
    if t.footnotes_level == RootFootnotes
        footnotes = getchildren(ast, K"Footnote")
        items = Iterators.flatten(children.(footnotes))
        footnotes_node = m(
            "section", 
            class="footnotes",
            m("ol", map(items) do item
                term, note... = children(item)
                term_id = "fn_" * idify(textify(ast, term))
                m("li", id=term_id, [
                    codegen.(Ref(t), Ref(ast), note), 
                    m("a", role="doc-backlink", href="#fnref_" * idify(textify(ast, term)), "↩︎")
                ])
            end)
        )
        push!(content, footnotes_node)
    else # collect all orphan footnotes
        footnotes = getchildren(ast, K"Footnote", AST.heading_level(t.footnotes_level))
        items = Iterators.flatten(children.(footnotes))
        footnotes_node = m(
            "section", 
            class="footnotes",
            m("ol", map(items) do item
                term, note... = children(item)
                term_id = "fn_" * idify(textify(ast, term))
                m("li", id=term_id, [
                    codegen.(Ref(t), Ref(ast), note), 
                    m("a", role="doc-backlink", href="#fnref_" * idify(textify(ast, term)), "↩︎")
                ])
            end)
        )
        push!(content, footnotes_node)
    end
    m("div", class = "norg", content)
end

function codegen(t::HTMLTarget, ::Paragraph, ast, node)
    res = []
    for c in children(node)
        gen = codegen(t, ast, c)
        if gen isa AbstractArray 
            append!(res, codegen(t, ast, c))
            push!(res, " ")
        else
            push!(res, gen)
        end
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
    tag = "a"
    param = "href"
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        kindoftarget = kind(first(children(node)))
        title = codegen(t, Word(), ast, last(children(node)))
        if kindoftarget == K"Footnote"
            id = "fnref_" * idify(title)
            text = m("sup", id=id, title)
        else
            text = title
        end
    elseif kind(first(node.children)) == K"MagicLocation"
        key = textify(ast, node)
        if haskey(ast.targets, key)
            kindoftarget, targetnoderef = ast.targets[key]
            title = codegen(t, Word(), ast, first(children(targetnoderef[])))
            if kindoftarget == K"Footnote"
                id = "fnref_" * idify(title)
                text = m("sup", id=id, title)
            else
                text = title
            end
        else
            text = codegen(t, ast, children(first(children(node)))[1])
        end
    elseif kind(first(node.children)) == K"WikiLocation"
        text = codegen(t, ast, children(first(children(node)))[1])
    elseif kind(first(node.children)) == K"TimestampLocation"
        text = textify(ast, first(node.children))
    else
        text = codegen(t, ast, first(node.children))
    end
    if kind(first(node.children)) == K"TimestampLocation"
        tag = "time"
        param = "datetime"
    end
    m(tag, href = target, text)
end

function codegen(t::HTMLTarget, ::URLLocation, ast, node)
    codegen(t, Word(), ast, first(children(node)))
end

function codegen(t::HTMLTarget, ::LineNumberLocation, ast, node)
    # Who are you, people who link to line location ?
    "#l-$(codegen(t, Word(), ast, first(children(node))))"
end

function codegen(t::HTMLTarget, ::DetachedModifierLocation, ast, node)
    kindoftarget = kind(first(children(node)))
    title = codegen(t, Word(), ast, last(children(node)))
    if AST.is_heading(kindoftarget)
        level_num = AST.heading_level(first(children(node)))
        level = "h" * string(level_num)
        "#" * idify(level * " " * title)
    elseif kindoftarget == K"Definition"
        "#" * "def_" * idify(title)
    elseif kindoftarget == K"Footnote"
        "#" * "fn_" * idify(title)
    else
        error("HTML code generation received an unknown Detached Modifier location: $kindoftarget")
    end
end

function codegen(t::HTMLTarget, ::MagicLocation, ast, node)
    key = textify(ast, node)
    if haskey(ast.targets, key)
        kindoftarget, targetnoderef = ast.targets[key]
        title = codegen(t, Word(), ast, first(children(targetnoderef[])))
        if AST.is_heading(kindoftarget)
            level_num = AST.heading_level(kindoftarget)
            level = "h" * string(level_num)
            "#" * idify(level * " " * title)
        elseif kindoftarget == K"Definition"
            "#" * "def_" * idify(title)
        elseif kindoftarget == K"Footnote"
            "#" * "fn_" * idify(title)
        else
            error("HTML code generation received an unknown Detached Modifier location: $kindoftarget")
        end
    else
        "" 
    end
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

function codegen(t::HTMLTarget, ::WikiLocation, ast, node)
    target, subtarget = children(node)
    target_loc = codegen(t, Word(), ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = "" 
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    "/" * target_loc * subtarget_loc
end

function codegen(t::HTMLTarget, ::TimestampLocation, ast, node)
    target = first(children(node))
    t1, t2 = parse_norg_timestamp(ast.tokens, target.start, target.stop)
    if !isnothing(t1)
        res = Dates.format(t1, dateformat"yyyy-mm-dd HH:MM:SS")
        if !isnothing(t2)
            res = res * "/" * Dates.format(t2, dateformat"yyyy-mm-dd HH:MM:SS")
        end
        res
    else
        "" 
    end
end

codegen(t::HTMLTarget, ::LinkDescription, ast, node) = [codegen(t, ast, c) for c in children(node)]

function codegen(t::HTMLTarget, ::Anchor, ast, node)
    text = codegen(t, ast, first(node.children))
    if length(children(node)) == 1
        target = "#"
    else
        target = codegen(t, ast, last(children(node)))
    end
    m("a", href = target, text)
end

function codegen(t::HTMLTarget, ::InlineLinkTarget, ast, node)
    text = []
    for c in children(node)
        append!(text, codegen(t, ast, c))
        push!(text, " ")
    end
    if !isempty(text)
        pop!(text) # remove last space
    end
    id = idify(join(textify(ast, node)))
    m("span", id=id, text)
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

    if t.footnotes_level == level_num
        footnotes = getchildren(node, K"Footnote")
        items = Iterators.flatten(children.(footnotes))
        footnotes_node = m(
            "section", 
            class="footnotes",
            m("ol", map(items) do item
                term, note... = children(item)
                term_id = "fn_" * idify(textify(ast, term))
                m("li", id=term_id, [
                    codegen.(Ref(t), Ref(ast), note), 
                    m("a", role="doc-backlink", href="fnref_" * idify(textify(ast, term)), "↩︎")
                ])
            end)
        )
        m("section", id=id_section, [heading, heading_content..., footnotes_node])
    else
        m("section", id=id_section, [heading, heading_content...])
    end
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
        if kind(first(others)) == K"TagParameter"
            lang = litteral(ast, first(others))
        else
            lang = litteral(ast, others[2])
        end
        "language-" * lang
    end
    m("pre", m("code", class=language, litteral(ast, last(others))))
end

function codegen(::HTMLTarget, ::TodoExtension, ast, node)
    status = first(children(node))
    checked = kind(status) == K"StatusDone"
    if checked
        m("input", checked="", type="checkbox", disabled="")
    else
        m("input", checked="", type="checkbox", disabled="")
    end
end

function codegen(t::HTMLTarget, ::Union{WeakCarryoverTag, StrongCarryoverTag}, ast, node)
    content = codegen(t, ast, last(children(node)))
    content = if content isa AbstractArray 
        m("div", content)
    else
        content
    end
    if length(children(node)) <= 2
        getproperty(content, textify(ast, first(children(node))))
    elseif length(children(node)) == 3
        label = textify(ast, first(children(node)))
        param = textify(ast, children(node)[2])
        content(;Symbol(label)=>param)
    else
        class = join(textify.(Ref(ast), children(node)[begin:end-1]), "-")
        getproperty(content, class)
    end
end

function codegen(t::HTMLTarget, ::Definition, ast, node)
    items = children(node)
    m("dl", collect(Iterators.flatten(map(items) do item
            term, def... = children(item)
            term_id = "def_" * idify(textify(ast, term))
            term_node = m("dt", id=term_id, codegen(t, ast, term))
            def_node = m("dd", codegen.(Ref(t), Ref(ast), def))
            term_node,def_node
        end
    )))
end

function codegen(t::HTMLTarget, ::Footnote, ast, node)
    if t.footnotes_level == InplaceFootnotes
        items = children(node)
        m(
            "section", 
            class="footnotes",
            m("ol", map(items) do item
                term, note... = children(item)
                term_id = "fn_" * idify(textify(ast, term))
                m("li", id=term_id, [
                    codegen.(Ref(t), Ref(ast), node), 
                    m("a", role="doc-backlink", href="#fnref_" * idify(textify(ast, term)), "↩︎")
                ])
            end)
        )
    else
        ""
    end
end

function codegen(t::HTMLTarget, ::Slide, ast, node)
    codegen(t, ast, first(children(node)))
end

function codegen(t::HTMLTarget, ::IndentSegment, ast, node)
    codegen.(Ref(t), Ref(ast), children(node))
end

export HTMLTarget

end
