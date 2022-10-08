Node = Norg.AST.Node
AST = Norg.AST

simple_link_tests = [
    ":norg_file:" => AST.FileLocation
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
    "/ example.txt" => AST.FileLinkableLocation
]

@testset "basic links: $target" for (link,target) in simple_link_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test l isa Node{AST.Link}
    @test loc isa Node{target}
end

@testset "basic links with description: $target" for (link,target) in simple_link_tests
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

@testset "Checking markup in link description :$link => $target" for (link,target) in simple_link_tests
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

subtarget_tests = [
    ":file:1" => AST.LineNumberLocation 
    ":file:* heading" => AST.DetachedModifierLocation
    ":file:** heading" => AST.DetachedModifierLocation
    ":file:*** heading" => AST.DetachedModifierLocation
    ":file:**** heading" => AST.DetachedModifierLocation
    ":file:***** heading" => AST.DetachedModifierLocation
    ":file:****** heading" => AST.DetachedModifierLocation
    ":file:******* heading" => AST.DetachedModifierLocation
    ":file:# magic" => AST.MagicLocation
    "/ file.txt:1" => AST.LineNumberLocation
]
@testset "Checking subtarget :$link => $target" for (link,target) in subtarget_tests
    s = "{$link}"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    l = first(children(ps))
    loc = first(children(l))
    @test loc.data.subtarget isa Node{target}
end
