"""HTML code generation using [HypertextLiteral.jl](https://github.com/JuliaPluto/HypertextLiteral.jl).
"""
module HTMLCodegen
using AbstractTrees
using HypertextLiteral
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

HTR = HypertextLiteral.Result

"""
Controls the position where footnotes are rendered. It can be within the lowest
heading level `i` by setting `HiFootnotes` or at the root of the document or
directly as it appears in the Norg document.
"""
@enum FootnotesLevel begin
    RootFootnotes = 0
    H1Footnotes = 1
    H2Footnotes = 2
    H3Footnotes = 3
    H4Footnotes = 4
    H5Footnotes = 5
    H6Footnotes = 6
    InplaceFootnotes = 7
end

"""
HTML target to feed [`codegen`](@ref).
"""
struct HTMLTarget <: CodegenTarget
    footnotes_level::FootnotesLevel
end

HTMLTarget() = HTMLTarget(RootFootnotes)

"""
A special target for link location, this ensure type-stability.
"""
struct HTMLLocationTarget <: CodegenTarget end

function do_footnote_item(ast, item)
    term, note... = children(item)
    term_id = "fn_" * idify(textify(ast, term))
    backref = "#fnref_" * idify(textify(ast, term))
    @htl """
        <li id=$term_id>
            $(codegen.(Ref(HTMLTarget()), Ref(ast), note))
            <a role="doc-backlink" href=$backref>↩︎</a>
        </li>
    """
end

function codegen(t::HTMLTarget, ast::NorgDocument)
    c = children(ast.root)
    if t.footnotes_level == RootFootnotes
        footnotes = getchildren(ast.root, K"Footnote")
        items = Iterators.flatten(children.(footnotes))
    else # collect all orphan footnotes
        footnotes = getchildren(
            ast.root, K"Footnote", AST.heading_kind(Int(t.footnotes_level))
        )
        items = Iterators.flatten(children.(footnotes))
    end
    footnotes_node = @htl """
    <section class="footnotes">
        <ol>
            $((do_footnote_item(ast, item) for item in items))
        </ol>
    </section>
    """
    @htl """<div class="norg">
        $((codegen(t, ast, c) for c in children(ast.root)))
        $footnotes_node
    </div>
    """
end

function codegen(t::HTMLTarget, ::Paragraph, ast::NorgDocument, node::Node)
    res = HTR[]
    for c in children(node)
        gen = codegen(t, ast, c)
        push!(res, gen)
    end
    @htl "<p>$res</p>"
end

function codegen(t::HTMLTarget, ::ParagraphSegment, ast::NorgDocument, node::Node)
    res = HTR[]
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    @htl "$res"
end

html_node(::Union{FreeFormBold,Bold}) = "b"
html_node(::Union{FreeFormItalic,Italic}) = "i"
html_node(::Union{FreeFormUnderline,Underline}) = "ins"
html_node(::Union{FreeFormStrikethrough,Strikethrough}) = "del"
html_node(::Union{FreeFormSpoiler,Spoiler}) = "span"
html_node(::Union{FreeFormSuperscript,Superscript}) = "sup"
html_node(::Union{FreeFormSubscript,Subscript}) = "sub"
html_node(::Union{FreeFormInlineCode,InlineCode}) = "code"

html_class(::Union{FreeFormBold,Bold}) = []
html_class(::Union{FreeFormItalic,Italic}) = []
html_class(::Union{FreeFormUnderline,Underline}) = []
html_class(::Union{FreeFormStrikethrough,Strikethrough}) = []
html_class(::Union{FreeFormSpoiler,Spoiler}) = ["spoiler"]
html_class(::Union{FreeFormSuperscript,Superscript}) = []
html_class(::Union{FreeFormSubscript,Subscript}) = []
html_class(::Union{FreeFormInlineCode,InlineCode}) = []

function codegen(
    t::HTMLTarget, s::T, ast::NorgDocument, node::Node
) where {T<:AttachedModifierStrategy}
    res = HTR[]
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    class = html_class(s)
    if isempty(class)
        @htl "<$(html_node(s))>$res</$(html_node(s))>"
    else
        @htl "<$(html_node(s)) class=$(html_class(s))>$res</$(html_node(s))>"
    end
end

function codegen(
    t::HTMLTarget, ::Union{NullModifier,FreeFormNullModifier}, ast::NorgDocument, node::Node
)
    @htl ""
end

function codegen(
    t::HTMLTarget, ::Union{InlineMath,FreeFormInlineMath}, ast::NorgDocument, node::Node
)
    res = HTR[]
    for c in children(node)
        push!(res, codegen(t, ast, c))
    end
    @htl "\$$res\$"
end

function codegen(
    t::HTMLTarget, ::Union{Variable,FreeFormVariable}, ast::NorgDocument, node::Node
)
    @htl ""
end

function codegen(t::HTMLTarget, ::Word, ast::NorgDocument, node::Node)
    if is_leaf(node)
        @htl "$(AST.litteral(ast, node))"
    else
        @htl "$((codegen(t, Word(), ast, c) for c in children(node)))"
    end
end
codegen(t::HTMLTarget, ::Escape, ast, node) = codegen(t, Word(), ast, node)

function codegen(t::HTMLTarget, ::Link, ast::NorgDocument, node::Node)
    target = codegen(HTMLLocationTarget(), ast, first(node.children))
    tag = "a"
    param = "href"
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        location = first(node.children)
        kindoftarget = kind(first(children(location)))
        title_node = last(children(location))
        title = textify(ast, title_node)
        title_node = codegen(t, ast, title_node)
        if kindoftarget == K"Footnote"
            id = "fnref_" * idify(title)
            text = @htl "<sup id=$id>$(title_node)</sup>"
        else
            text = title_node
        end
    elseif kind(first(node.children)) == K"MagicLocation"
        location = first(node.children)
        key = textify(ast, last(children(location)))
        if haskey(ast.targets, key)
            kindoftarget, targetnoderef = ast.targets[key]
            kindoftarget = kind(kindoftarget)
            title_node = first(children(targetnoderef[]))
            title = textify(ast, title_node)
            title_node = codegen(t, ast, title_node)
            if kindoftarget == K"Footnote"
                id = "fnref_" * idify(title)
                text = @htl "<sup id=$id>$title_node</sup>"
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
        text = codegen(HTMLLocationTarget(), ast, first(node.children))
    end
    if kind(first(node.children)) == K"TimestampLocation"
        tag = "time"
        param = "datetime"
    end
    @htl """<$tag $(Pair(param, target))>$text</$tag>"""
end

function codegen(t::HTMLLocationTarget, ::URLLocation, ast::NorgDocument, node::Node)
    return textify(ast, first(children(node)))
end

function codegen(t::HTMLLocationTarget, ::LineNumberLocation, ast::NorgDocument, node::Node)
    # Who are you, people who link to line location ?
    return "#l-$(textify(ast, first(children(node))))"
end

function codegen(
    t::HTMLLocationTarget, ::DetachedModifierLocation, ast::NorgDocument, node::Node
)
    kindoftarget = kind(first(children(node)))
    title_node = last(children(node))
    title = textify(ast, title_node)
    if AST.is_heading(kindoftarget)
        level_num = AST.heading_level(first(children(node)))
        level = "h" * string(level_num)
        "#" * idify(level * " " * title)
    elseif kindoftarget == K"Definition"
        "#" * "def_" * idify(title)
    elseif kindoftarget == K"Footnote"
        "#" * "fn_" * idify(title)
    else
        error(
            "HTML code generation received an unknown Detached Modifier location: $kindoftarget",
        )
    end
end

function codegen(t::HTMLLocationTarget, ::MagicLocation, ast::NorgDocument, node::Node)
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
            error(
                "HTML code generation received an unknown Detached Modifier location: $kindoftarget",
            )
        end
    else
        ""
    end
end

function codegen(t::HTMLLocationTarget, ::FileLocation, ast::NorgDocument, node::Node)
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
        subtarget_loc = "#" * codegen(t, ast, subtarget)::String
    end

    return start * target_loc * subtarget_loc
end

function codegen(t::HTMLLocationTarget, ::NorgFileLocation, ast::NorgDocument, node::Node)
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
        subtarget_loc = "#" * codegen(t, ast, subtarget)::String
    end

    return start * target_loc * subtarget_loc
end

function codegen(t::HTMLLocationTarget, ::WikiLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    target_loc = textify(ast, target)
    if kind(subtarget) == K"None"
        subtarget_loc = ""
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)::String
    end
    return "/" * target_loc * subtarget_loc
end

function codegen(t::HTMLLocationTarget, ::TimestampLocation, ast::NorgDocument, node::Node)
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

function codegen(t::HTMLTarget, ::LinkDescription, ast::NorgDocument, node::Node)
    @htl "$((codegen(t, ast, c) for c in children(node)))"
end

function codegen(t::HTMLTarget, ::Anchor, ast::NorgDocument, node::Node)
    text = codegen(t, ast, first(node.children))
    if length(children(node)) == 1
        target = "#"
    else
        target = codegen(HTMLLocationTarget(), ast, last(children(node)))
    end
    @htl "<a href=$target>$text</a>"
end

function codegen(t::HTMLTarget, ::InlineLinkTarget, ast::NorgDocument, node::Node)
    text = HTR[]
    for c in children(node)
        push!(text, codegen(t, ast, c))
        push!(text, @htl " ")
    end
    if !isempty(text)
        pop!(text) # remove last space
    end
    id = idify(join(textify(ast, node)))
    @htl "<span id=$id>$text</span>"
end

function codegen(t::HTMLTarget, ::Heading, ast::NorgDocument, node::Node)
    level_num = AST.heading_level(node)
    level = "h" * string(level_num)
    heading_title, content... = children(node)
    title = textify(ast, heading_title)
    id_title = idify(level * " " * title)
    heading = @htl "<$level id=$id_title>$(codegen(t, ast, heading_title))</$level>"
    heading_content = HTR[codegen(t, ast, c)::HTR for c in content]
    id_section = idify("section " * id_title)

    if t.footnotes_level == level_num
        footnotes = getchildren(node, K"Footnote")
        items = Iterators.flatten(children.(footnotes))
        footnotes_node = @htl """
        <section class="footnotes">
            <ol>
            $(map(do_footnote_item(ast, item)))
            </ol>
        </section>
        """
        @htl """
        <section id=$id_section>
        $heading
        $heading_content
        $footnotes_node
        </section>
        """
    else
        @htl """
        <section id=$id_section>
        $heading
        $heading_content
        </section>
        """
    end
end

codegen(::HTMLTarget, ::StrongDelimiter, ast, node) = @htl ""
codegen(::HTMLTarget, ::WeakDelimiter, ast, node) = @htl ""
codegen(::HTMLTarget, ::HorizontalRule, ast, node) = @htl "<hr/>"

function codegen(t::HTMLTarget, ::UnorderedList, ast::NorgDocument, node::Node)
    @htl "<ul>$([codegen(t, ast, c) for c in children(node)])</ul>"
end

function codegen(t::HTMLTarget, ::OrderedList, ast::NorgDocument, node::Node)
    @htl "<ol>$([codegen(t, ast, c) for c in children(node)])</ol>"
end

function codegen(t::HTMLTarget, ::NestableItem, ast::NorgDocument, node::Node)
    @htl "<li>$([codegen(t, ast, c) for c in children(node)])</li>"
end

function codegen(t::HTMLTarget, ::Quote, ast::NorgDocument, node::Node)
    # <blockquote> does not have an 'item' notion, so we have to short-circuit
    # that.
    res = HTR[]
    for c in children(node)
        append!(res, codegen.(Ref(t), Ref(ast), children(c)))
    end
    @htl "<blockquote>$res</blockquote>"
end

function codegen(t::HTMLTarget, ::StandardRangedTag, ast::NorgDocument, node::Node)
    tag, others... = children(node)
    tag_litteral = litteral(ast, tag)
    if tag_litteral == "comment"
        @htl ""
    elseif tag_litteral == "example"
        @htl """
        <pre>
            <code class="language-norg">
                $(litteral(ast, last(others)))
            </code>
        </pre>
        """
    elseif tag_litteral == "details"
        @htl """
        <detail>
            <summary>Details</summary>
            $([codegen(t, ast, c) for c in children(last(others))])
        </detail>
        """
    elseif tag_litteral == "group"
        @htl """
        <div>
            $([codegen(t, ast, c) for c in children(last(others))])
        </div>
        """
    else
        @warn "Unknown standard ranged tag." tag_litteral ast.tokens[AST.start(node)] ast.tokens[AST.stop(
            node
        )]
        @htl """
        $([codegen(t, ast, c) for c in children(last(others))])
        """
    end
end

function codegen(::HTMLTarget, ::Verbatim, ast::NorgDocument, node::Node)
    # cowardly ignore any verbatim that is not code
    tag, others... = children(node)
    if litteral(ast, tag) != "code"
        return @htl ""
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
    @htl """
    <pre>
        <code class=$language>
            $(litteral(ast, last(others)))
        </code>
    </pre>
    """
end

function codegen(::HTMLTarget, ::TodoExtension, ast::NorgDocument, node::Node)
    status = first(children(node))
    checked = kind(status) == K"StatusDone"
    if checked
        @htl """<input checked type="checkbox" disabled/>"""
    else
        @htl """<input type="checkbox" disabled/>"""
    end
end

function codegen(
    t::HTMLTarget,
    ::Union{WeakCarryoverTag,StrongCarryoverTag},
    ast::NorgDocument,
    node::Node,
)
    content = codegen(t, ast, last(children(node)))
    params = Dict{Symbol,String}()
    if length(children(node)) <= 2
        params[:class] = textify(ast, first(children(node)))
    elseif length(children(node)) == 3
        label = textify(ast, first(children(node)))
        param = textify(ast, children(node)[2])
        params[Symbol(label)] = param
    else
        class = join(textify.(Ref(ast), children(node)[begin:(end - 1)]), "-")
        params[:class] = class
    end
    @htl "<div $params>$content</div>"
end

function codegen(t::HTMLTarget, ::Definition, ast::NorgDocument, node::Node)
    items = children(node)
    content = collect(Iterators.flatten(
        map(items) do item
            term, def... = children(item)
            term_id = "def_" * idify(textify(ast, term))
            term_node = @htl "<dt id=$term_id>$(codegen(t, ast, term))</dt>"
            def_node = @htl "<dd>$(codegen.(Ref(t), Ref(ast), def))</dd>"
            term_node, def_node
        end,
    ))
    @htl "<dl>$content</dl>"
end

function codegen(t::HTMLTarget, ::Footnote, ast::NorgDocument, node::Node)
    if t.footnotes_level == InplaceFootnotes
        items = children(node)
        @htl """
        <section class="footnotes">
            <ol>
            $(map(do_footnote_item(ast, item)))
            </ol>
        </section>
        """
    else
        @htl ""
    end
end

function codegen(t::HTMLTarget, ::Slide, ast::NorgDocument, node::Node)
    @htl "$(codegen(t, ast, first(children(node))))"
end

function codegen(t::HTMLTarget, ::IndentSegment, ast::NorgDocument, node::Node)
    @htl "$((codegen(t, ast, c) for c in children(node)))"
end

export HTMLTarget

end
