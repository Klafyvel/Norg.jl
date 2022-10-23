Node = Norg.AST.Node

@testset "Two newlines should separate two paragraphs." begin
    ast = parse(Norg.AST.NorgDocument,
                "Hi I am first paragraph.\n\nOh, hello there, I am second paragraph !")
    p1, p2 = children(ast)
    @test kind(p1) == K"Paragraph"
    @test kind(p2) == K"Paragraph"
end

@testset "One newline should separate two paragraph segments." begin
    ast = parse(Norg.AST.NorgDocument,
                "Hi I am first paragraph segment...\nAnd I am second paragraph segment !\n\nOh, hello there, I am second paragraph !")
    p1, p2 = children(ast)
    ps1,ps2 = children(p1)
    ps3 = first(children(p2))
    @test kind(p1) == K"Paragraph"
    @test kind(p2) == K"Paragraph"
    @test kind(ps1) == K"ParagraphSegment"
    @test kind(ps2) == K"ParagraphSegment"
    @test kind(ps3) == K"ParagraphSegment"
end
