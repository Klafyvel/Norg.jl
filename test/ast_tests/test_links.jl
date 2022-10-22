Node = Norg.AST.Node
AST = Norg.AST

simple_link_tests = [":norg_file:" => K"NorgFileLocation"
                     "* heading" => K"DetachedModifierLocation"
                     "** heading" => K"DetachedModifierLocation"
                     "*** heading" => K"DetachedModifierLocation"
                     "**** heading" => K"DetachedModifierLocation"
                     "***** heading" => K"DetachedModifierLocation"
                     "****** heading" => K"DetachedModifierLocation"
                     "******* heading" => K"DetachedModifierLocation"
                     "# magic" => K"MagicLocation"
                     "42" => K"LineNumberLocation"
                     "https://example.org" => K"URLLocation"
                     "file://example.txt" => K"URLLocation"
                     "/ example.txt" => K"FileLocation"]

@testset "basic links: $target" for (link, target) in simple_link_tests
    s = "{$link} other"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l, space, word = children(ps)
    loc = first(children(l))
    @test kind(l) == K"Link"
    @test kind(loc) == target
    @test kind(space) == K"WordNode"
    @test join(value.(ast.tokens[space.start:space.stop])) == " "
end

@testset "basic links with description: $target" for (link, target) in simple_link_tests
    s = "{$link}[descr]"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    descr = last(children(l))
    @test kind(l) == K"Link"
    @test kind(loc) == target
    @test kind(descr) == K"LinkDescription"
    descr_ps = first(children(descr))
    descr_word = first(children(descr_ps))
    @test join(value.(ast.tokens[descr_word.start:descr_word.stop])) == "descr"
end

@testset "Checking markup in link description :$link => $target" for (link, target) in simple_link_tests
    s = "{$link}[*descr*]"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    descr = last(children(l))
    @test kind(l) == K"Link"
    @test kind(loc) == target
    @test kind(descr) == K"LinkDescription"
    ps = first(children(descr))
    @test kind(ps) == K"ParagraphSegment"
    b = first(children(ps))
    @test kind(b) == K"Bold"
end

@testset "Test special neorg root path" begin
    s = "{:\$file:}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    target = first(children(loc))
    @test kind(target) == K"FileNorgRootTarget"
    s = "{/ \$file}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    target = first(children(loc))
    @test kind(target) == K"FileNorgRootTarget"
end

subtarget_tests = [":file:1" => K"LineNumberLocation"
                   ":file:* heading" => K"DetachedModifierLocation"
                   ":file:** heading" => K"DetachedModifierLocation"
                   ":file:*** heading" => K"DetachedModifierLocation"
                   ":file:**** heading" => K"DetachedModifierLocation"
                   ":file:***** heading" => K"DetachedModifierLocation"
                   ":file:****** heading" => K"DetachedModifierLocation"
                   ":file:******* heading" => K"DetachedModifierLocation"
                   ":file:# magic" => K"MagicLocation"
                   "/ file.txt:1" => K"LineNumberLocation"]
@testset "Checking subtarget :$link => $target" for (link, target) in subtarget_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test kind(last(children(loc))) == target
end

leaves_tests = [
    ":test:" => [K"FileTarget", K"None"]
    "* heading" => [K"Heading1", K"WordNode"]
    "** heading" => [K"Heading2", K"WordNode"]
    "*** heading" => [K"Heading3", K"WordNode"]
    "**** heading" => [K"Heading4", K"WordNode"]
    "***** heading" =>[K"Heading5", K"WordNode"]
    "****** heading" =>[K"Heading6", K"WordNode"]
    "******* heading" =>[K"Heading6", K"WordNode"]
    "# magic" => [K"WordNode"]
    "42" => [K"LineNumberTarget"]
    "https://example.org" => [K"URLTarget"]
    "file://example.txt" => [K"URLTarget"]
    "/ example.txt" => [K"FileTarget", K"None"]    ]
@testset "Checking leaves :$link => $target" for (link, target) in leaves_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    for (l,t) in zip(collect(Leaves(ast)), target)
        @test kind(l) == t
    end
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
    @test kind(anchor1) == K"Anchor"
    @test kind(anchor2) == K"Anchor"
    @test length(children(anchor1)) == 1
    @test length(children(anchor2)) == 2
    @test kind(first(children(anchor1))) == K"LinkDescription"
    @test kind(first(children(anchor2))) == K"LinkDescription"
    @test kind(last(children(anchor2))) == K"URLLocation"
end

anchor_tests = [(input = "[heading 1 anchor]\n\n[heading 1 anchor]{* Heading 1}",
target = K"DetachedModifierLocation")
                (input = "[heading 2 anchor]\n\n[heading 2 anchor]{** Heading 2}",
                 target = K"DetachedModifierLocation")
                (input = "[heading 3 anchor]\n\n[heading 3 anchor]{*** Heading 3}",
                 target = K"DetachedModifierLocation")
                (input = "[heading 4 anchor]\n\n[heading 4 anchor]{**** Heading 4}",
                 target = K"DetachedModifierLocation")
                (input = "[heading 5 anchor]\n\n[heading 5 anchor]{***** Heading 5}",
                 target = K"DetachedModifierLocation")
                (input = "[heading 6 anchor]\n\n[heading 6 anchor]{****** Heading 6}",
                 target = K"DetachedModifierLocation")
                (input = "[heading 7 anchor]\n\n[heading 7 anchor]{******* Heading 7}",
                 target = K"DetachedModifierLocation")
                (input = "[generic anchor]\n\n[generic anchor]{# Generic}",
                 target = K"MagicLocation")
                (input = "[norg file anchor]\n\n[norg file anchor]{:norg_file:}",
                 target = K"NorgFileLocation")
                (input = "[external heading 1 anchor]\n\n[external heading 1 anchor]{:norg_file:* Heading 1}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external heading 2 anchor]\n\n[external heading 2 anchor]{:norg_file:** Heading 2}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external heading 3 anchor]\n\n[external heading 3 anchor]{:norg_file:*** Heading 3}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external heading 4 anchor]\n\n[external heading 4 anchor]{:norg_file:**** Heading 4}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external heading 5 anchor]\n\n[external heading 5 anchor]{:norg_file:***** Heading 5}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external heading 7 anchor]\n\n[external heading 6 anchor]{:norg_file:****** Heading 6}",
                 target = K"NorgFileLocation",
                 subtarget = K"DetachedModifierLocation")
                (input = "[external generic anchor]\n\n[external generic anchor]{:norg_file:# Generic}",
                 target = K"NorgFileLocation",
                 subtarget = K"MagicLocation")
                (input = "[non-norg file anchor]\n\n[non-norg file anchor]{/ external_file.txt}",
                 target = K"FileLocation")
                (input = "[url anchor]\n\n[url anchor]{https://github.com/}",
                 target = K"URLLocation")
                (input = "[file anchor]\n\n[file anchor]{file:///dev/null}",
                 target = K"URLLocation")]

@testset "Testing anchor : $(t.target)" for t in anchor_tests
    ast = parse(AST.NorgDocument, t.input)
    anchor1, anchor2 = first.(children.(first.(children.(children(ast)))))
    @test kind(anchor1) == K"Anchor"
    @test kind(anchor2) == K"Anchor"
    @test length(children(anchor1)) == 1
    @test length(children(anchor2)) == 2
    target = last(children(anchor2))
    @test kind(target) == t.target
    if :subtarget in keys(t)
        @test kind(last(children(target))) == t.subtarget
    end
end
