using Hyperscript: Node
using Norg
using Documenter

# pre-rendering the Norg specification
using Hyperscript, AbstractTrees
s = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end;
md_path = joinpath(@__DIR__, "src", "1.0-specification.md")
ast = norg(s)
function mk_toc(ast)
    toc_tree = filter(!isnothing, [mk_toc(ast, c) for c in children(ast.root)])
end
function mk_toc(ast, node)
    c = children(node)
    if !Norg.AST.is_heading(node)
        nothing
    else 
        h, node_children... =  c
        level = Norg.AST.heading_level(node)
        (title=Norg.Codegen.textify(ast, h),
        level = level,
        children=filter([mk_toc(ast, c) for c in node_children]) do c
                if isnothing(c)
                    false
                elseif c.level >= 3
                    false
                elseif level > c.level
                    false
                else
                    true
                end
            end
        )
    end
end
toc = mk_toc(ast)
function mk_html_toc(toc_elem)
    [m("a", href="#"*"h$(toc_elem.level)-"*Norg.Codegen.idify(toc_elem.title), toc_elem.title),
    m("ul", [m("li", mk_html_toc(t)) for t in toc_elem.children])
    ]
end
toc_html = m("ul", [m("li", mk_html_toc(c)) for c in toc])
open(md_path, "w") do f
    write(f, """This is an automated rendering of the [norg specification](https://github.com/nvim-neorg/norg-specs) using Norg.jl.

    # Table of contents
    """)
    write(f, "```@raw html\n")
    write(f, string(toc_html|>Pretty))
    write(f, "\n")
    write(f, string(norg(Norg.HTMLTarget(), s)|>Pretty))
    write(f, "\n```")
end

DocMeta.setdocmeta!(Norg, :DocTestSetup, :(using Norg); recursive = true)

makedocs(;
         modules = [Norg],
         authors = "Hugo Levy-Falk <hugo@klafyvel.me> and contributors",
         repo = "https://github.com/Klafyvel/Norg.jl/blob/{commit}{path}#{line}",
         sitename = "Norg.jl",
         format = Documenter.HTML(;
                                  prettyurls = true,
                                  canonical = "https://klafyvel.github.io/Norg.jl",
                                  edit_link = "main",
                                  assets = String[]),
         pages = [
             "Home" => "index.md",
             "Specification" => "1.0-specification.md",
             "Internals" => [
                "How parsing works" => "internals.md",
                "Private API" => [
                    "internals/kinds.md"
                    "internals/tokens.md"
                    "internals/scanners.md"
                    "internals/match.md"
                    "internals/parser.md"
                    "Code generation" => [
                        "internals/codegen/index.md"
                        "Targets" => [
                            "internals/codegen/html.md"
                            "internals/codegen/json.md"
                        ]
                    ]
                ]
            ]
         ])


deploydocs(;
           repo = "github.com/Klafyvel/Norg.jl",
           devbranch = "main")
