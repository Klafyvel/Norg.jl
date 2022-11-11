using Norg
using Documenter

DocMeta.setdocmeta!(Norg, :DocTestSetup, :(using Norg); recursive = true)

makedocs(;
         modules = [Norg],
         authors = "Hugo Levy-Falk <hugo@klafyvel.me> and contributors",
         repo = "https://github.com/Klafyvel/Norg.jl/blob/{commit}{path}#{line}",
         sitename = "Norg.jl",
         format = Documenter.HTML(;
                                  prettyurls = get(ENV, "CI", "false") ==
                                               "true",
                                  canonical = "https://klafyvel.github.io/Norg.jl",
                                  edit_link = "main",
                                  assets = String[]),
         pages = [
             "Home" => "index.md",
             "Specification" => "1.0-specification.md",
             "Internals" => "internals.md",
         ])

# Monkey patching into documenter...
using Hyperscript
s = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end;
html_path = joinpath(@__DIR__, "build", "1.0-specification.html")
initial_html = open(html_path) do f
    read(f, String)    
end
header, footer = split(initial_html, "<p>{}</p>")
open(html_path, "w") do f
 write(f, header)
 write(f, string(parse(Norg.HTMLTarget, s)|>Pretty))
 write(f, footer)
end

deploydocs(;
           repo = "github.com/Klafyvel/Norg.jl",
           devbranch = "main")
