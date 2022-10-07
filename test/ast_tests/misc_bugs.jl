Node = Norg.AST.Node

@testset "Square bracket should be words when they are not following links (layer 2)" begin
    s = """- [+] demo

    * some text
    ** more
        - [ ] nice
        - [-] {https://github.com/}[i error]
    """
    ast = parse(Norg.AST.NorgDocument, s)
    @test ast isa Node{Norg.AST.NorgDocument}
end
