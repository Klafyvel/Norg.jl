using Norg
using Documenter

DocMeta.setdocmeta!(Norg, :DocTestSetup, :(using Norg); recursive=true)

makedocs(;
    modules=[Norg],
    authors="Hugo Levy-Falk <hugo@klafyvel.me> and contributors",
    repo="https://github.com/klafyvel/Norg.jl/blob/{commit}{path}#{line}",
    sitename="Norg.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://klafyvel.github.io/Norg.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Internals" => "internals.md",
    ],
)

deploydocs(;
    repo="github.com/klafyvel/Norg.jl",
    devbranch="main",
)
