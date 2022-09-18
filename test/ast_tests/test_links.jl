Node = Norg.AST.Node

@testset "basic links" begin
    s = "{https://klafyvel.me}"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.Link}
    @test nodes[5] isa Node{Norg.AST.URLLocation}
end

@testset "basic links with description" begin
    s = "{https://klafyvel.me}[My website]"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.Link}
    @test nodes[5] isa Node{Norg.AST.URLLocation}
    @test nodes[13] isa Node{Norg.AST.LinkDescription}
end

@testset "Checking no markup in url locations" begin
    s = "{https:// *klafyvel* .me}[My website]"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test !any(isa.(nodes, Norg.AST.Bold))
end

@testset "Checking markup in url description" begin
    s = "{https://klafyvel.me}[My *website*]"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[end - 1] isa Node{Norg.AST.Bold}
end
