Node = Norg.AST.Node
AST = Norg.AST

simple_link_tests = [":norg_file:" => AST.FileLocation
                     "* heading" => AST.DetachedModifierLocation
                     "** heading" => AST.DetachedModifierLocation
                     "*** heading" => AST.DetachedModifierLocation
                     "**** heading" => AST.DetachedModifierLocation
                     "***** heading" => AST.DetachedModifierLocation
                     "****** heading" => AST.DetachedModifierLocation
                     "******* heading" => AST.DetachedModifierLocation
                     "# magic" => AST.MagicLocation
                     "42" => AST.LineNumberLocation
                     "https://example.org" => AST.URLLocation
                     "file://example.txt" => AST.URLLocation
                     "/ example.txt" => AST.FileLinkableLocation]

@testset "basic links: $target" for (link, target) in simple_link_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test l isa Node{AST.Link}
    @test loc isa Node{target}
end

@testset "basic links with description: $target" for (link, target) in simple_link_tests
    s = "{$link}[descr]"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    descr = last(children(l))
    @test l isa Node{AST.Link}
    @test loc isa Node{target}
    @test descr isa Node{AST.LinkDescription}
end

@testset "Checking markup in link description :$link => $target" for (link, target) in simple_link_tests
    s = "{$link}[*descr*]"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    descr = last(children(l))
    @test l isa Node{AST.Link}
    @test loc isa Node{target}
    @test descr isa Node{AST.LinkDescription}
    @test first(children(descr)) isa Node{Norg.AST.Bold}
end

@testset "Test special neorg root path" begin
    s = "{:\$file:}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test loc.data.use_neorg_root
    s = "{/ \$file}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test loc.data.use_neorg_root
end

subtarget_tests = [":file:1" => AST.LineNumberLocation
                   ":file:* heading" => AST.DetachedModifierLocation
                   ":file:** heading" => AST.DetachedModifierLocation
                   ":file:*** heading" => AST.DetachedModifierLocation
                   ":file:**** heading" => AST.DetachedModifierLocation
                   ":file:***** heading" => AST.DetachedModifierLocation
                   ":file:****** heading" => AST.DetachedModifierLocation
                   ":file:******* heading" => AST.DetachedModifierLocation
                   ":file:# magic" => AST.MagicLocation
                   "/ file.txt:1" => AST.LineNumberLocation]
@testset "Checking subtarget :$link => $target" for (link, target) in subtarget_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test loc.data.subtarget isa Node{target}
end

@testset "Basic anchor example from the spec." begin
    s = """
    [Neorg] is a fancy organizational tool for everyone.

    I like shilling [Neorg]{https://github.com/nvim-neorg/neorg} sorry :(
    """
    ast = parse(Norg.AST.NorgDocument, s)
    ps1, ps2 = first.(children.(children(ast)))
    anchor1 = first(children(ps1))
    anchor2 = children(ps2)[7]
    @test anchor1 isa Node{AST.Anchor}
    @test anchor2 isa Node{AST.Anchor}
    @test anchor1.data.has_definition == false
    @test anchor2.data.has_definition == true
    @test first(children(anchor1)) isa Node{AST.LinkDescription}
    @test first(children(anchor2)) isa Node{AST.LinkDescription}
    @test last(children(anchor2)) isa Node{AST.URLLocation}
end

anchor_tests = [(input = "[heading 1 anchor]\n\n[heading 1 anchor]{* Heading 1}",
                 target = AST.DetachedModifierLocation("Heading 1", 1))
                (input = "[heading 2 anchor]\n\n[heading 2 anchor]{** Heading 2}",
                 target = AST.DetachedModifierLocation("Heading 2", 2))
                (input = "[heading 3 anchor]\n\n[heading 3 anchor]{*** Heading 3}",
                 target = AST.DetachedModifierLocation("Heading 3", 3))
                (input = "[heading 4 anchor]\n\n[heading 4 anchor]{**** Heading 4}",
                 target = AST.DetachedModifierLocation("Heading 4", 4))
                (input = "[heading 5 anchor]\n\n[heading 5 anchor]{***** Heading 5}",
                 target = AST.DetachedModifierLocation("Heading 5", 5))
                (input = "[heading 6 anchor]\n\n[heading 6 anchor]{****** Heading 6}",
                 target = AST.DetachedModifierLocation("Heading 6", 6))
                (input = "[heading 7 anchor]\n\n[heading 7 anchor]{******* Heading 7}",
                 target = AST.DetachedModifierLocation("Heading 7", 7))
                (input = "[generic anchor]\n\n[generic anchor]{# Generic}",
                 target = AST.MagicLocation("Generic"))
                (input = "[norg file anchor]\n\n[norg file anchor]{:norg_file:}",
                 target = AST.FileLocation(false, "norg_file", nothing))
                (input = "[external heading 1 anchor]\n\n[external heading 1 anchor]{:norg_file:* Heading 1}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 1", 1))
                (input = "[external heading 2 anchor]\n\n[external heading 2 anchor]{:norg_file:** Heading 2}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 2", 2))
                (input = "[external heading 3 anchor]\n\n[external heading 3 anchor]{:norg_file:*** Heading 3}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 3", 3))
                (input = "[external heading 4 anchor]\n\n[external heading 4 anchor]{:norg_file:**** Heading 4}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 4", 4))
                (input = "[external heading 5 anchor]\n\n[external heading 5 anchor]{:norg_file:***** Heading 5}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 5", 5))
                (input = "[external heading 7 anchor]\n\n[external heading 6 anchor]{:norg_file:****** Heading 6}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.DetachedModifierLocation("Heading 6", 6))
                (input = "[external generic anchor]\n\n[external generic anchor]{:norg_file:# Generic}",
                 target = AST.FileLocation(false, "norg_file", nothing),
                 subtarget = AST.MagicLocation("Generic"))
                (input = "[non-norg file anchor]\n\n[non-norg file anchor]{/ external_file.txt}",
                 target = AST.FileLinkableLocation(false, "external_file.txt",
                                                   nothing))
                (input = "[url anchor]\n\n[url anchor]{https://github.com/}",
                 target = AST.URLLocation("https://github.com/"))
                (input = "[file anchor]\n\n[file anchor]{file:///dev/null}",
                 target = AST.URLLocation("file:///dev/null"))]

@testset "Testing anchor : $(t.target)" for t in anchor_tests
    ast = parse(AST.NorgDocument, t.input)
    anchor1, anchor2 = first.(children.(first.(children.(children(ast)))))
    @test anchor1 isa Node{AST.Anchor}
    @test anchor2 isa Node{AST.Anchor}
    @test anchor1.data.has_definition == false
    @test anchor2.data.has_definition == true
    target = last(children(anchor2))
    @test target isa Node{typeof(t.target)}
    for p in fieldnames(typeof(t.target))
        target_prop = getproperty(t.target, p)
        if isnothing(target_prop)
            continue
        end
        @test getproperty(target.data, p) == target_prop
    end
    if :subtarget in keys(t)
        @test target.data.subtarget isa Node{typeof(t.subtarget)}
    end
end
