@testset "JSON target" begin
    using JSON
    # generated JSON correctness is checked directly with pandoc
    using pandoc_jll

    function pandoc_approval(json)
        io_err = PipeBuffer()
        try
            pandoc() do pandoc_bin
                io = PipeBuffer()
                write(io, json)
                run(
                    pipeline(
                        `$(pandoc_bin) -f json -t json`;
                        stdin=io,
                        stdout=devnull,
                        stderr=io_err,
                    ),
                )
            end
        catch e
            err = String(take!(io_err))
            @error "Pandoc error" err
            return false
        end
        return true
    end

    @testset "Test paragraphs" begin
        s = "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        pars = json["blocks"]
        @test pars[1]["t"] == "Para"
        @test pars[2]["t"] == "Para"
    end

    simple_markups_nodes = [
        ('*', "Strong"),
        ('/', "Emph"),
        ('_', "Underline"),
        ('-', "Strikeout"),
        ('!', "Span"),
        ('^', "Superscript"),
        (',', "Subscript"),
        ('`', "Code"),
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

    @testset "Test correct markup for $m" for (m, node) in simple_markups_nodes
        s = "$(m)inner$(m)"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        b = json["blocks"][1]["c"][1]
        @test b["t"] == node
    end

    @testset "Test correct class for $m" for (m, class) in simple_markups_class
        s = "$(m)inner$(m)"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        b = json["blocks"][1]["c"][1]
        if !isnothing(class)
            @test first(b["c"])[2][1] == class
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
        ("? test", "/test", "test")
    ]

    @testset "Test links: $link" for (link, target, text) in simple_link_tests
        s = "{$link}"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        link = json["blocks"][1]["c"][1]
        @test link["t"] == "Link"
        @test link["c"][2][1]["t"] == "Str"
        @test link["c"][2][1]["c"] == text
        @test link["c"][3][1] == target
    end

    @testset "Test links with description: $link" for (link, target) in simple_link_tests
        s = "{$link}[website]"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        link = json["blocks"][1]["c"][1]
        @test link["t"] == "Link"
        @test link["c"][2][1]["t"] == "Str"
        @test link["c"][2][1]["c"] == "website"
        @test link["c"][3][1] == target
    end

    @testset "Anchors with embedded definition: $link" for (link, target) in
                                                           simple_link_tests
        s = "[website]{$link}"
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        link = json["blocks"][1]["c"][1]
        @test link["t"] == "Link"
        @test link["c"][2][1]["t"] == "Str"
        @test link["c"][2][1]["c"] == "website"
        @test link["c"][3][1] == target
    end

    @testset "Verbatim code" begin
        s = """@code julia
        using Norg
        s = "*Hi there*"
        json = norg(Norg.JSONTarget(), s)
        @end
        """
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        cb = json["blocks"][1]
        @test cb["t"] == "CodeBlock"
        attr, content = cb["c"]
        @test attr[2][1] == "julia"
        @test content ==
            """using Norg\ns = "*Hi there*"\njson = norg(Norg.JSONTarget(), s)\n"""
    end

    heading_levels = 1:6

    @testset "Level $i heading" for i in heading_levels
        s = """$(repeat("*", i)) heading
        text
        """
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        container = json["blocks"][1]
        @test container["t"] == "Div"
        attr, content = container["c"]
        @test first(attr) == "section-h$i-heading"
        heading = first(content)
        @test heading["t"] == "Header"
        hlevel, attr, title = heading["c"]
        @test hlevel == i
        @test attr[1] == "h$i-heading"
        @test title[1]["c"] == "heading"
    end

    nestable_lists = ['~' => "OrderedList", '-' => "BulletList", ">" => "BlockQuote"]
    @testset "$target nestable" for (m, target) in nestable_lists
        s = """$m Hello, salute sinchero oon kydooke
        $m Shintero yuo been na
        $m Na sinchere fedicheda
        """
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        list = json["blocks"][1]
        @test list["t"] == target
    end

    @testset "inline link" begin
        s = """<inline link target>"""
        json_str = norg(JSONTarget(), s)
        @test pandoc_approval(json_str)
        json = JSON.parse(json_str)
        p = json["blocks"][1]
        @test length(p["c"]) == 1
        span = first(p["c"])
        @test span["t"] == "Span"
        attrs, inlines = span["c"]
        id = first(attrs)
        @test id == "inline-link-target"
    end

    @testset "Parse the entire Norg spec without error." begin
        s = open(Norg.NORG_SPEC_PATH) do f
            read(f, String)
        end
        json = norg(JSONTarget(), s)
        @test pandoc_approval(json)
    end
end
