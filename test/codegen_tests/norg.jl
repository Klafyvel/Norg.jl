@testset "Norg target" begin

    @testset "Test paragraphs" begin
        s = "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !"
        res = String(take!(norg(NorgTarget(), s)))
        @test res == s
    end

    simple_markups = [
        '*',
        '/',
        '_',
        '-',
        '!',
        '^',
        ',',
        '`',
        '\$',
        '&',
    ]
    @testset "Test correct markup for $m" for m in simple_markups
        s = "$(m)inner$(m)"
        res = String(take!(norg(NorgTarget(), s)))
        @test res == s
    end

    @testset "Escaping modifier $m" for m in simple_markups
        s = "This is \\$(m)normal\\$(m)"
        res = String(take!(norg(NorgTarget(), s)))
        @test res == s
    end

    # simple_link_tests = [
    #     (":norg_file:", "norg_file", "norg_file")
    #     ("* heading", "#h1-heading", "heading")
    #     ("** heading", "#h2-heading", "heading")
    #     ("*** heading", "#h3-heading", "heading")
    #     ("**** heading", "#h4-heading", "heading")
    #     ("***** heading", "#h5-heading", "heading")
    #     ("****** heading", "#h6-heading", "heading")
    #     ("******* heading", "#h6-heading", "heading")
    #     ("# magic", "", "magic")
    #     ("42", "#l-42", "#l-42")
    #     ("https://example.org", "https://example.org", "https://example.org")
    #     ("file://example.txt", "file://example.txt", "file://example.txt")
    #     ("/ example.txt", "example.txt", "example.txt")
    #     ("? test", "/test", "test")
    # ]
    #
    # @testset "Test links: $link" for (link, target, text) in simple_link_tests
    #     s = "{$link}"
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     link = html.root[2][1][1][1]
    #     @test tag(link) == :a
    #     @test getattr(link, "href") == target
    #     @test string(link[1]) == text
    # end
    #
    # @testset "Test links with description: $link" for (link, target) in simple_link_tests
    #     s = "{$link}[website]"
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     link = html.root[2][1][1][1]
    #     @test tag(link) == :a
    #     @test getattr(link, "href") == target
    #     @test string(link[1]) == "website"
    # end
    #
    # @testset "Anchors with embedded definition: $link" for (link, target) in
    #                                                        simple_link_tests
    #     s = "[website]{$link}"
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     link = html.root[2][1][1][1]
    #     @test tag(link) == :a
    #     @test getattr(link, "href") == target
    #     @test string(link[1]) == "website"
    # end
    #
    # @testset "Verbatim code" begin
    #     s = """@code julia
    #     using Norg, Hyperscript
    #     s = "*Hi there*"
    #     html = norg(HTMLTarget(), s) |> string |> parsehtml
    #     @end
    #     """
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     pre = html.root[2][1][1]
    #     @test tag(pre) == :pre
    #     code = pre[2]
    #     @test tag(code) == :code
    #     @test haskey(attrs(code), "class")
    #     @test getattr(code, "class") == "language-julia"
    # end
    #
    # heading_levels = 1:6
    #
    # @testset "Level $i heading" for i in heading_levels
    #     s = """$(repeat("*", i)) heading
    #     text
    #     """
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     section = html.root[2][1][1]
    #     @test tag(section) == :section
    #     @test haskey(attrs(section), "id")
    #     @test getattr(section, "id") == "section-h$(i)-heading"
    #     h, p = children(section)
    #     @test tag(h) == Symbol("h$i")
    #     @test haskey(attrs(h), "id")
    #     @test getattr(h, "id") == "h$(i)-heading"
    #     @test text(first(children(h))) == "heading"
    #     @test tag(p) == :p
    #     @test text(first(children(p))) == "text"
    # end
    #
    # nestable_lists = ['~' => :ol, '-' => :ul]
    # @testset "$target list" for (m, target) in nestable_lists
    #     s = """$m Hello, salute sinchero oon kydooke
    #     $m Shintero yuo been na
    #     $m Na sinchere fedicheda
    #     """
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     list = html.root[2][1][1]
    #     @test tag(list) == target
    #     lis = children(list)
    #     @test all(tag.(lis) .== :li)
    # end
    #
    # @testset "quote" begin
    #     s = "> I QUOTE you"
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     q = html.root[2][1][1]
    #     @test tag(q) == :blockquote
    # end
    #
    # @testset "inline link" begin
    #     s = """<inline link target>"""
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     p = html.root[2][1][1]
    #     @test length(children(p)) == 1
    #     span = first(children(p))
    #     @test haskey(attrs(span), "id")
    #     @test getattr(span, "id") == "inline-link-target"
    # end
    #
    # @testset "Parse the entier Norg spec without error." begin
    #     s = open(Norg.NORG_SPEC_PATH, "r") do f
    #         read(f, String)
    #     end
    #     html = parsehtml(string(norg(HTMLTarget(), s)))
    #     @test html isa HTMLDocument
    # end
end
