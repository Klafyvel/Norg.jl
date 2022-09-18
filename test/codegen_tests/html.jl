@testset "Test paragraphs" begin
    s = "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !"
    html = Norg.codegen(Norg.HTMLTarget, Norg.parse_norg(Norg.tokenize(s)))
    pars = getfield(html, :children)
    @test getfield(pars[1], :tag) == "p"
    @test getfield(pars[2], :tag) == "p"
end

simple_markups_nodes = [
    ('*', "b"),
    ('/', "i"),
    ('_', "ins"),
    ('-', "del"),
    ('!', "span"),
    ('^', "sup"),
    (',', "sub"),
    ('`', "code"),
]

simple_markups_class = [
    ('*', nothing),
    ('/', nothing),
    ('_', nothing),
    ('-', nothing),
    ('!', "spoiler"),
    ('^', nothing),
    (',', nothing),
    ('`', nothing),
]

@testset "Test correct markup for $m" for (m, html_node) in simple_markups_nodes
    s = "$(m)inner$(m)"
    html = Norg.codegen(Norg.HTMLTarget, Norg.parse_norg(Norg.tokenize(s)))
    b = first(getfield(first(getfield(html, :children)), :children))
    @test getfield(b, :tag) == html_node
end

@testset "Test correct class for $m" for (m, html_class) in simple_markups_class
    s = "$(m)inner$(m)"
    html = Norg.codegen(Norg.HTMLTarget, Norg.parse_norg(Norg.tokenize(s)))
    b = first(getfield(first(getfield(html, :children)), :children))
    if isnothing(html_class)
        @test !haskey(getfield(b, :attrs), "class")
    else
        @test haskey(getfield(b, :attrs), "class")
        @test getfield(b, :attrs)["class"] == html_class
    end
end
