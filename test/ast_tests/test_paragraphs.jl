Node = Norg.AST.Node

@testset "Two newlines should separate two paragraphs." begin
    ast = parse(Norg.AST.NorgDocument,
                "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !")
    nodes = collect(PreOrderDFS(ast))
    @test nodes[2] isa Node{Norg.AST.Paragraph}
    @test nodes[14] isa Node{Norg.AST.Paragraph}
end

@testset "One newline should separate two paragraph segments." begin
    ast = parse(Norg.AST.NorgDocument,
                "Hi I am first paragraph segment...\nAnd I am second paragraph segment !\n\nOh, hello there, I am second paragraph !")
    pars = children(ast)
    subpars = collect(Iterators.flatten(children.(pars)))
    @test pars[1] isa Node{Norg.AST.Paragraph}
    @test pars[2] isa Node{Norg.AST.Paragraph}
    @test children(pars[1])[1] isa Node{Norg.AST.ParagraphSegment}
    @test children(pars[1])[2] isa Node{Norg.AST.ParagraphSegment}
    @test children(pars[2])[1] isa Node{Norg.AST.ParagraphSegment}
end
