"""
Pandoc AST code generation. The best reference of Pandoc's AST I could find is
[here](https://hackage.haskell.org/package/pandoc-types-1.22.2.1/docs/Text-Pandoc-Definition.html)

The code generated consists in `OrderedDict`s from [OrderedCollections.jl](https://github.com/JuliaCollections/OrderedCollections.jl) that
follow the Pandoc JSON AST API. You can then export using *e.g.* [JSON.jl](https://github.com/JuliaIO/JSON.jl).
"""
module JSONCodegen
using Base: CacheHeaderIncludes
using AbstractTrees

using ..AST
using ..Strategies
using ..Kinds
using ..Tokens
import ..CodegenTarget
import ..codegen
import ..textify
import ..idify

jsonify(p::Pair{Symbol,Symbol}) = "$(jsonify(first(p))):$(jsonify(last(p)))"
jsonify(p::Pair{Symbol,Int}) = "$(jsonify(first(p))):$(jsonify(last(p)))"
jsonify(p::Pair{Symbol,String}) = "$(jsonify(first(p))):$(jsonify(last(p)))"
jsonify(a::Vector{Pair{Symbol,String}}) = "{" * join(jsonify.(a)::Vector{String}, ",") * "}"
jsonify(a::Vector) = "[" * join(jsonify.(a), ",") * "]"
jsonify(x::String) = x
jsonify(x::Int) = string(x)
jsonify(x::Symbol) = "\"$(x)\""

"""
JSON target to feed [`codegen`](@ref).

You can specify a pandoc api version, but this only changes the version number
announced in the generated output.
"""
struct JSONTarget <: CodegenTarget
    pandocapiversion::Vector{Int}
end
JSONTarget() = JSONTarget([1, 23])

"""
A special target for link location, this ensure type-stability.
"""
struct JSONLocationTarget <: CodegenTarget end
function codegen(::JSONLocationTarget, _, _, _)
    return error(
        "Trying to generate a non location node with target `JSONLocationTarget`. You found a bug in JSON code generation.",
    )
end

function codegen_children(t::JSONTarget, ast::AST.NorgDocument, node::Node)
    res = String[]
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(res, r)
        end
    end
    return res
end

function codegen(t::JSONTarget, ast::AST.NorgDocument)
    return jsonify(
        [
            Symbol("pandoc-api-version") => jsonify(t.pandocapiversion)
            :meta => "{}"
            :blocks => jsonify(codegen_children(t, ast, ast.root))
        ],
    )
end

function codegen(t::JSONTarget, ::Paragraph, ast::NorgDocument, node::Node)
    res = String[]
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(res, r)
            push!(res, jsonify([:t => jsonify(:SoftBreak)]))
        end
    end
    if !isempty(res)
        pop!(res) # remove last softbreak
    end
    return jsonify([
        :t => jsonify(:Para)
        :c => jsonify(res)
    ])
end

function codegen(t::JSONTarget, ::ParagraphSegment, ast::NorgDocument, node::Node)
    return join(codegen_children(t, ast, node), ",")
end

pandoc_t(::Union{FreeFormBold,Bold}) = :Strong
pandoc_t(::Union{FreeFormItalic,Italic}) = :Emph
pandoc_t(::Union{FreeFormUnderline,Underline}) = :Underline
pandoc_t(::Union{FreeFormStrikethrough,Strikethrough}) = :Strikeout
pandoc_t(::Union{FreeFormSpoiler,Spoiler}) = :Span
pandoc_t(::Union{FreeFormSuperscript,Superscript}) = :Superscript
pandoc_t(::Union{FreeFormSubscript,Subscript}) = :Subscript
pandoc_t(::Union{FreeFormInlineCode,InlineCode}) = :Code

pandoc_attr(::Union{FreeFormBold,Bold}) = []
pandoc_attr(::Union{FreeFormItalic,Italic}) = []
pandoc_attr(::Union{FreeFormUnderline,Underline}) = []
pandoc_attr(::Union{FreeFormStrikethrough,Strikethrough}) = []
function pandoc_attr(::Union{FreeFormSpoiler,Spoiler})
    return ["\"\"", jsonify(["\"spoiler\""]), jsonify([])]
end
pandoc_attr(::Union{FreeFormSuperscript,Superscript}) = []
pandoc_attr(::Union{FreeFormSubscript,Subscript}) = []
pandoc_attr(::Union{FreeFormInlineCode,InlineCode}) = ["\"\"", jsonify([]), jsonify([])]

function codegen(
    t::JSONTarget, s::T, ast::NorgDocument, node::Node
) where {T<:AttachedModifierStrategy}
    res = String[]
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(res, r)
            push!(res, jsonify([:t => jsonify(:SoftBreak)]))
        end
    end
    attr = pandoc_attr(s)
    if isempty(attr)
        jsonify([
            :t => jsonify(pandoc_t(s))
            :c => jsonify(res)
        ])
    else
        jsonify([
            :t => jsonify(pandoc_t(s))
            :c => jsonify([jsonify(attr), jsonify(res)])
        ])
    end
end

function codegen(
    ::JSONTarget, ::Union{InlineMath,FreeFormInlineMath}, ast::NorgDocument, node::Node
)
    return jsonify(
        [
            :t => jsonify(:Math)
            :c => jsonify([
                jsonify([:t => jsonify(:InlineMath)]),
                "\"" * textify(ast, node, escape_string) * "\"",
            ])
        ],
    )
end

function codegen(::JSONTarget, ::Union{Variable,FreeFormVariable}, ::NorgDocument, ::Node)
    return ""
end

function codegen(
    ::JSONTarget, ::Union{NullModifier,FreeFormNullModifier}, ::NorgDocument, ::Node
)
    return ""
end

function codegen(
    ::JSONTarget, s::Union{InlineCode,FreeFormInlineCode}, ast::NorgDocument, node::Node
)
    return jsonify(
        [
            :t => jsonify(pandoc_t(s))
            :c => jsonify([
                jsonify(pandoc_attr(s)), "\"" * textify(ast, node, escape_string) * "\""
            ])
        ],
    )
end

function codegen(t::JSONTarget, ::Word, ast::NorgDocument, node::Node)
    if is_leaf(node) && (AST.stop(node) - AST.start(node) > 0)
        jsonify([
            :t => jsonify(:Str)
            :c => "\"$(textify(ast, node, escape_string))\""
        ])
    elseif is_leaf(node)
        token = first(ast.tokens[AST.start(node):AST.stop(node)])
        if Tokens.is_whitespace(token)
            jsonify([:t => jsonify(:Space)])
        else
            jsonify([
                :t => jsonify(:Str)
                :c => "\"$(textify(ast, node, escape_string))\""
            ])
        end
    else
        jsonify([codegen(t, Word(), ast, c) for c in children(node)])
    end
end
codegen(t::JSONTarget, ::Escape, ast, node) = codegen(t, ast, first(children(node)))

function codegen(t::JSONTarget, ::Link, ast::NorgDocument, node::Node)
    if length(node.children) > 1
        text = codegen(t, ast, last(node.children))
    elseif kind(first(node.children)) == K"DetachedModifierLocation"
        text = jsonify([codegen(t, ast, children(first(children(node)))[2])])
    elseif kind(first(node.children)) == K"MagicLocation"
        text = jsonify([codegen(t, ast, children(first(children(node)))[1])])
    elseif kind(first(node.children)) == K"WikiLocation"
        text = jsonify([codegen(t, ast, children(first(children(node)))[1])])
    elseif kind(first(node.children)) == K"TimestampLocation"
        text = "\"" * textify(ast, first(node.children), escape_string) * "\""
    else
        text = jsonify([
            jsonify([
                :t => jsonify(:Str),
                :c =>
                    "\"" * codegen(JSONLocationTarget(), ast, first(node.children)) * "\"",
            ]),
        ])
    end
    if kind(first(node.children)) == K"TimestampLocation"
        jsonify([
            :t => jsonify(:Str)
            :c => text
        ])
    else
        target = codegen(JSONLocationTarget(), ast, first(node.children))
        jsonify(
            [
                :t => jsonify(:Link)
                :c => jsonify([
                    jsonify([Symbol(""), jsonify(String[]), jsonify(String[])]),
                    text,
                    jsonify(["\"" * target * "\"", Symbol("")]),
                ])
            ],
        )
    end
end

# fallback
function codegen(::JSONTarget, ::URLLocation, ast, node)
    return error("You found a bug in URL location JSON code generation.")
end
codegen(::JSONLocationTarget, ::URLLocation, ast, node) = textify(ast, node, escape_string)

# fallback
function codegen(::JSONTarget, ::LineNumberLocation, ast, node)
    return error("You found a bug in line number location JSON code generation.")
end
function codegen(::JSONLocationTarget, ::LineNumberLocation, ast::NorgDocument, node::Node)
    # Who are you, people who link to line location ?
    return "#l-$(textify(ast, node, escape_string))"
end

# fallback
function codegen(::JSONTarget, ::DetachedModifierLocation, ast, node)
    return error("You found a bug in detached modifier location JSON code generation.")
end
function codegen(
    ::JSONLocationTarget, ::DetachedModifierLocation, ast::NorgDocument, node::Node
)
    kindoftarget = kind(first(children(node)))
    title = textify(ast, last(children(node)), escape_string)
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
            "JSON code generation received an unknown Detached Modifier location: $kindoftarget",
        )
    end
end

# fallback
function codegen(::JSONTarget, ::MagicLocation, ast, node)
    return error("You found a bug in magic location JSON code generation.")
end
function codegen(::JSONLocationTarget, ::MagicLocation, ast::NorgDocument, node::Node)
    key = textify(ast, node, escape_string)
    if haskey(ast.targets, key)
        kindoftarget, targetnoderef = ast.targets[key]::Tuple{Kind,Ref{Node}}
        title = textify(
            ast, first(children(targetnoderef[]::Node)::Vector{Node}), escape_string
        )
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
                "JSON code generation received an unknown Detached Modifier location: $kindoftarget",
            )
        end
    else
        ""
    end
end

# fallback
function codegen(::JSONTarget, ::FileLocation, ast, node)
    return error("You found a bug in file location JSON code generation.")
end
function codegen(t::JSONLocationTarget, ::FileLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/"
    else
        start = ""
    end
    target_loc = textify(ast, target, escape_string)
    if kind(subtarget) == K"None"
        subtarget_loc = ""
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end

    return start * target_loc * subtarget_loc
end

# fallback
function codegen(::JSONTarget, ::NorgFileLocation, ast, node)
    return error("You found a bug in norg file location JSON code generation.")
end
function codegen(t::JSONLocationTarget, ::NorgFileLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    if kind(target) == K"FileNorgRootTarget"
        start = "/"
    else
        start = ""
    end
    target_loc = textify(ast, target, escape_string)
    if kind(subtarget) == K"None"
        subtarget_loc = ""
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end

    return start * target_loc * subtarget_loc
end

# fallback
function codegen(::JSONTarget, ::WikiLocation, ast, node)
    return error("You found a bug in wiki location JSON code generation.")
end
function codegen(t::JSONLocationTarget, ::WikiLocation, ast::NorgDocument, node::Node)
    target, subtarget = children(node)
    target_loc = textify(ast, target, escape_string)
    if kind(subtarget) == K"None"
        subtarget_loc = ""
    else
        subtarget_loc = "#" * codegen(t, ast, subtarget)
    end
    return "/" * target_loc * subtarget_loc
end

# fallback
function codegen(::JSONTarget, ::TimestampLocation, ast, node)
    return error("You found a bug in timestamp location JSON code generation.")
end
function codegen(::JSONLocationTarget, ::TimestampLocation, ast::NorgDocument, node::Node)
    return textify(ast, node, escape_string)
end

function codegen(t::JSONTarget, ::LinkDescription, ast::NorgDocument, node::Node)
    return jsonify(codegen_children(t, ast, node))
end

function codegen(t::JSONTarget, ::Anchor, ast::NorgDocument, node::Node)
    text = codegen(t, ast, first(node.children))
    if length(children(node)) == 1
        target = "#"
    else
        target = codegen(JSONLocationTarget(), ast, last(children(node)))
    end
    return jsonify(
        [
            :t => jsonify(:Link)
            :c => jsonify([
                jsonify([Symbol(""), jsonify([]), jsonify([])]),
                text,
                jsonify(["\"" * target * "\"", Symbol("")]),
            ])
        ],
    )
end

function codegen(t::JSONTarget, ::InlineLinkTarget, ast::NorgDocument, node::Node)
    text = String[]
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(text, r)
            push!(text, " ")
        end
    end
    if !isempty(text)
        pop!(text) # remove last space
    end
    id = idify(join(textify(ast, node, escape_string)))
    return jsonify(
        [
            :t => jsonify(:Span)
            :c => jsonify([jsonify(["\"" * id * "\"", jsonify([]), jsonify(Any[])]), text])
        ],
    )
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
    title = "\"" * textify(ast, heading_title_node, escape_string) * "\""
    id_title = "\"" * idify(level * " " * title) * "\""
    heading = jsonify(
        [
            :t => jsonify(:Header)
            :c => jsonify([
                level_num,
                jsonify([id_title, jsonify([]), jsonify([])]),
                jsonify([heading_title]),
            ])
        ],
    )
    id_section = "\"" * idify("section " * id_title) * "\""
    return jsonify(
        [
            :t => jsonify(:Div)
            :c => jsonify([
                jsonify([id_section, jsonify([]), jsonify([])]),
                jsonify([heading, heading_content...]),
            ])
        ],
    )
end

codegen(::JSONTarget, ::StrongDelimiter, ast::NorgDocument, node::Node) = ""
codegen(::JSONTarget, ::WeakDelimiter, ast::NorgDocument, node::Node) = ""
codegen(::JSONTarget, ::HorizontalRule, ast::NorgDocument, node::Node) = ""

function codegen_nestable_children(t::JSONTarget, ast::NorgDocument, node::Node)
    res = []
    for c in children(node)
        r = codegen(t, ast, c)
        if !isempty(r)
            push!(res, r)
        end
    end
    return res
end

function codegen(t::JSONTarget, ::UnorderedList, ast::NorgDocument, node::Node)
    return jsonify(
        [
            :t => jsonify(:BulletList)
            :c => jsonify(codegen_nestable_children(t, ast, node))
        ]
    )
end

function codegen(t::JSONTarget, ::OrderedList, ast::NorgDocument, node::Node)
    return jsonify(
        [
            :t => jsonify(:OrderedList)
            :c => jsonify([
                jsonify([
                    "1",
                    jsonify([:t => jsonify(:Decimal)]),
                    jsonify([:t => jsonify(:Period)]),
                ]),
                jsonify(codegen_nestable_children(t, ast, node)),
            ])
        ],
    )
end

function codegen(t::JSONTarget, ::NestableItem, ast::NorgDocument, node::Node)
    res = String[]
    for c in children(node)
        if kind(c) == K"IndentSegment"
            append!(res, codegen(t, ast, c))
        elseif kind(c) ∉
            KSet"TimestampExtension PriorityExtension DueDateExtension StartDateExtension"
            r = codegen(t, ast, c)
            if !isempty(r)
                push!(res, r)
            end
        end
    end
    return jsonify(res)
end

function codegen(t::JSONTarget, ::Quote, ast::NorgDocument, node::Node)
    # <blockquote> does not have an 'item' notion, so we have to short-circuit
    # that.
    res = String[]
    for c in children(node)
        append!(res, collect(filter(!isempty, codegen.(Ref(t), Ref(ast), children(c)))))
    end
    return jsonify([
        :t => jsonify(:BlockQuote)
        :c => jsonify(res)
    ])
end

function codegen(t::JSONTarget, ::StandardRangedTag, ast::NorgDocument, node::Node)
    tag, others... = children(node)
    tag_litteral = litteral(ast, tag)
    if tag_litteral == "comment"
        ""
    elseif tag_litteral == "example"
        jsonify(
            [
                :t => jsonify(:CodeBlock)
                :c => jsonify([
                    jsonify([Symbol(""), jsonify(["\"norg\""]), jsonify([])]),
                    "\"" * textify(ast, last(others), escape_string) * "\"",
                ])
            ],
        )
    elseif tag_litteral == "details"
        # TODO
        ""
    elseif tag_litteral == "group"
        jsonify([
            :t => jsonify(:Div),
            :c => jsonify([
                jsonify([Symbol(""), jsonify([]), jsonify([])]),
                jsonify(codegen_children(t, ast, last(others))),
            ]),
        ])
    else
        @warn "Unknown standard ranged tag." tag_litteral ast.tokens[AST.start(node)] ast.tokens[AST.stop(
            node
        )]
        jsonify(
            [
                :t => jsonify(:Div)
                :c => jsonify([
                    jsonify([Symbol(""), jsonify([]), jsonify([])]),
                    jsonify(codegen_children(t, ast, last(others))),
                ])
            ],
        )
    end
end

function codegen(::JSONTarget, ::Verbatim, ast::NorgDocument, node::Node)
    # cowardly ignore any verbatim that is not code
    tag, others... = children(node)
    if litteral(ast, tag) != "code"
        return ""
    end
    if length(others) == 1
        jsonify(
            [
                :t => jsonify(:CodeBlock)
                :c => jsonify([
                    jsonify([Symbol(""), jsonify([]), jsonify([])]),
                    "\"" * textify(ast, last(others), escape_string) * "\"",
                ])
            ],
        )
    else
        language = if kind(first(others)) == K"TagParameter"
            litteral(ast, first(others))
        else
            litteral(ast, others[2])
        end
        jsonify(
            [
                :t => jsonify(:CodeBlock)
                :c => jsonify([
                    jsonify([Symbol(""), jsonify(["\"" * language * "\""]), jsonify([])]),
                    "\"" * textify(ast, last(others), escape_string) * "\"",
                ])
            ],
        )
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
    return jsonify(
        [
            :t => jsonify(:Plain)
            :c => jsonify([jsonify([
                :t => jsonify(:Str)
                :c => s
            ])])
        ]
    )
end

function codegen(
    t::JSONTarget,
    c::Union{WeakCarryoverTag,StrongCarryoverTag},
    ast::NorgDocument,
    node::Node,
)
    content = codegen(t, ast, last(children(node)))
    label = "\"" * textify(ast, first(children(node)), escape_string) * "\""
    # TODO: there's most likely some room for improvement here, as some contents
    # already have a mechanism for attributes, so the Div is not needed.
    attr = [Symbol(""), jsonify([]), jsonify([])]
    if length(children(node)) <= 2
        attr[2] = jsonify([label])
    elseif length(children(node)) == 3
        attr[3] = jsonify([
            jsonify([label, "\"" * textify(ast, children(node)[2], escape_string) * "\""])
        ])
    else
        attr[2] = jsonify([
            "\"" *
            join(textify.(Ref(ast), children(node)[1:(end - 1)], escape_string), "-") *
            "\"",
        ])
    end

    t =
        if kind(node) == K"WeakCarryoverTag" &&
            kind(last(children(node))) == K"ParagraphSegment"
            :Span
        else
            :Div
        end
    if !(first(content) == '[')
        content = jsonify([content])
    end
    return jsonify([:t => jsonify(t), :c => jsonify([jsonify(attr), content])])
end

function codegen(t::JSONTarget, ::Definition, ast::NorgDocument, node::Node)
    items = children(node)
    return jsonify(
        [
            :t => jsonify(:DefinitionList)
            :c => jsonify(map(items) do item
                term, def... = children(item)
                term_id = "def_" * idify(textify(ast, term, escape_string))
                term_node = jsonify(
                    [
                        :t => jsonify(:Span)
                        :c => jsonify([
                            jsonify(["\"" * term_id * "\"", jsonify([]), jsonify([])]),
                            jsonify([codegen(t, ast, term)]),
                        ])
                    ],
                )
                def_node = jsonify(codegen.(Ref(t), Ref(ast), def))
                jsonify([jsonify([term_node]), jsonify([def_node])])
            end)
        ],
    )
end

function codegen(::JSONTarget, ::Footnote, ast::NorgDocument, node::Node)
    # Return nothing, pandoc expects footnotes to be defined where they are called.
    return ""
end

function codegen(t::JSONTarget, ::Slide, ast::NorgDocument, node::Node)
    return codegen(t, ast, first(children(node)))
end

function codegen(t::JSONTarget, ::IndentSegment, ast::NorgDocument, node::Node)
    return codegen_children(t, ast, node)
end

export JSONTarget

end
