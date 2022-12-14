@testset "HTML target" begin
using Hyperscript

@testset "Test paragraphs" begin
    s = "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !"
    html = Norg.codegen(Norg.HTMLTarget(), Norg.parse_norg(Norg.tokenize(s)))
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
    html = Norg.codegen(Norg.HTMLTarget(), Norg.parse_norg(Norg.tokenize(s)))
    b = first(getfield(first(getfield(html, :children)), :children))
    @test getfield(b, :tag) == html_node
end

@testset "Test correct class for $m" for (m, html_class) in simple_markups_class
    s = "$(m)inner$(m)"
    html = Norg.codegen(Norg.HTMLTarget(), Norg.parse_norg(Norg.tokenize(s)))
    b = first(getfield(first(getfield(html, :children)), :children))
    if isnothing(html_class)
        @test !haskey(getfield(b, :attrs), "class")
    else
        @test haskey(getfield(b, :attrs), "class")
        @test getfield(b, :attrs)["class"] == html_class
    end
end

simple_link_tests = [
(":norg_file:", "norg_file", "norg_file")
("* heading", "#h1-heading", "heading")
("** heading", "#h2-heading", "heading")
("*** heading", "#h3-heading", "heading")
("**** heading", "#h4-heading", "heading")
("***** heading", "#h5-heading", "heading")
("****** heading", "#h6-heading", "heading")
("******* heading", "#h6-heading", "heading")
("# magic", "", "magic")
("42", "#l-42", "#l-42")
("https://example.org", "https://example.org", "https://example.org")
("file://example.txt", "file://example.txt", "file://example.txt")
("/ example.txt", "example.txt", "example.txt")
]

@testset "Test links: $link" for (link, target, text) in simple_link_tests
    s = "{$link}"
    html = parse(HTMLTarget(), s)
    link = first(getfield(first(getfield(html, :children)), :children))
    @test getfield(link, :tag) == "a"
    @test getfield(link, :attrs)["href"] == target
    @test first(getfield(link, :children)) == text
end

@testset "Test links with description: $link" for (link, target) in simple_link_tests
    s = "{$link}[website]"
    html = parse(HTMLTarget(), s)
    link = first(getfield(first(getfield(html, :children)), :children))
    @test getfield(link, :tag) == "a"
    @test getfield(link, :attrs)["href"] == target
    @test first(getfield(link, :children)) == "website"
end

@testset "Anchors with embedded definition: $link" for (link, target) in simple_link_tests
    s = "[website]{$link}"
    html = parse(HTMLTarget(), s)
    link = first(getfield(first(getfield(html, :children)), :children))
    @test getfield(link, :tag) == "a"
    @test getfield(link, :attrs)["href"] == target
    @test first(getfield(link, :children)) == "website"
end

@testset "Verbatim code" begin
    s = """@code julia
    using Norg, Hyperscript
    s = "*Hi there*"
    html = parse(Norg.HTMLTarget, s)
    html |> Pretty
    @end
    """
    html = parse(HTMLTarget(), s)
    pre = first(getfield(html, :children))
    @test getfield(pre, :tag) == "pre"
    code = first(getfield(pre, :children))
    @test getfield(code, :tag) == "code"
    @test haskey(getfield(code, :attrs), "class")
    @test getfield(code, :attrs)["class"] == "language-julia"
end

heading_levels = 1:6

@testset "Level $i heading" for i in heading_levels
    s = """$(repeat("*", i)) heading
    text
    """
    html = parse(HTMLTarget(), s)
    section = first(getfield(html, :children))
    @test getfield(section, :tag) == "section"
    @test haskey(getfield(section, :attrs), "id")
    @test getfield(section, :attrs)["id"] == "section-h$(i)-heading"
    h,p = getfield(section, :children)
    @test getfield(h, :tag) == "h$i"
    @test haskey(getfield(h, :attrs), "id")
    @test getfield(h, :attrs)["id"] == "h$(i)-heading"
    @test first(getfield(h, :children)) == "heading"
    @test getfield(p, :tag) == "p"
    @test first(getfield(p, :children)) == "text"
end

nestable_lists = ['~'=>"ol", '-'=>"ul"]
@testset "$target list" for (m, target) in nestable_lists
    s = """$m Hello, salute sinchero oon kydooke
    $m Shintero yuo been na
    $m Na sinchere fedicheda
    """
    html = parse(HTMLTarget(), s)
    list = first(getfield(html, :children))
    @test getfield(list, :tag) == target
    lis = getfield(list, :children)
    @test all(getfield.(lis, :tag) .== "li")
end

@testset "quote" begin
    s = "> I QUOTE you"
    html = parse(HTMLTarget(), s)
    q = first(getfield(html, :children))
    @test getfield(q, :tag) == "blockquote"
end

@testset "Parse the entier Norg spec without error." begin
    s = open(Norg.NORG_SPEC_PATH, "r") do f
        read(f, String)
    end
    html = parse(HTMLTarget(), s)
    @test html isa Hyperscript.Node{Hyperscript.HTMLSVG}
end
end
