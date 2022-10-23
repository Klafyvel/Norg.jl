# model : https://github.com/nvim-neorg/tree-sitter-norg/blob/dev/test/corpus/markup.txt

Node = Norg.AST.Node

simple_markups = [
("*", K"Bold"),
("/", K"Italic") ,
("_", K"Underline"),
("-", K"Strikethrough"),
("!", K"Spoiler"),
("^", K"Superscript"),
(",", K"Subscript"),
("`", K"InlineCode"),
]

@testset "Standalone markup for $m" for (m,k) in simple_markups
    ast = parse(Norg.AST.NorgDocument, "$(m)inner$(m)")
    @test ast isa Norg.AST.NorgDocument
    p = first(children(ast))
    @test kind(p) == K"Paragraph"
    ps = first(children(p))
    @test kind(ps) == K"ParagraphSegment"
    marknode = first(children(ps))
    @test kind(marknode) == k
    w = first(children(marknode))
    @test kind(w) == K"WordNode"
    @test join(Norg.Tokens.value.(ast.tokens[w.start:w.stop])) == "inner"
end

@testset "Markup inside a sentence for $m" for (m, k) in simple_markups
    ast = parse(Norg.AST.NorgDocument,
                "When put inside a sentence $(m)inner$(m).")
    @test ast isa Norg.AST.NorgDocument
    p = first(children(ast))
    @test kind(p) == K"Paragraph"
    ps = first(children(p))
    @test kind(ps) == K"ParagraphSegment"
    marknode = children(ps)[11]
    @test kind(marknode) == k
    w = first(children(marknode))
    @test kind(w) == K"WordNode"
    @test join(Norg.Tokens.value.(ast.tokens[w.start:w.stop])) == "inner"
end

simple_nested_outer = [
    ('*', K"Bold"),
    ('/', K"Italic"),
    ('_', K"Underline"),
    ('-', K"Strikethrough"),
    ('!', K"Spoiler"),
    ('^', K"Superscript"),
    (',', K"Subscript"),
]

@testset "Nested markup $n inside $m" for (m, T) in simple_nested_outer,
                                          (n, U) in simple_markups
    if m == n
        continue
    end
    s = "$(m)Nested $(n)inner$(n)$(m)"
    ast = parse(Norg.AST.NorgDocument, s)
    outernode = first(children(first(children(first(children(ast))))))
    @test kind(outernode) == T
    innernode = last(children(outernode))
    @test kind(innernode) == U
    w = first(children(innernode))
    @test kind(w) == K"WordNode"
    @test join(Norg.Tokens.value.(ast.tokens[w.start:w.stop])) == "inner"
end

@testset "Nested markup $m inside `" for (m, T) in simple_markups
    if m == "`"
        continue
    end
    s = "`Nested $(m)inner$(m)`"
    ast = parse(Norg.AST.NorgDocument, s)
    outernode = first(children(first(children(first(children(ast))))))
    @test kind(outernode) == K"InlineCode"
    for n in children(outernode)
        @test kind(n) == K"WordNode"
    end
end

@testset "Escaping modifier $m" for (m, _) in simple_markups
    s = "This is \\$(m)normal\\$(m)"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    for n in children(ps)
        @test kind(n) ∈ [K"Escape", K"WordNode"]
    end
end

@testset "No empty modifier $m" for (m, T) in simple_markups
    s = "nothing to see $(m)$(m) here"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    for n in children(ps)
        @test kind(n) == K"WordNode"
    end
end

@testset "First closing modifier has precedence" begin
    s = "*first bold* some /italic/ and not bold*"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    b = children(ps)[1]
    i = children(ps)[5]
    @test kind(b) == K"Bold"
    @test kind(i) == K"Italic"
end

@testset "First closing modifier has precedence" begin
    s = "*This /is bold*/"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    b = children(ps)[1]
    @test kind(b) == K"Bold"
end

@testset "Verbatim precedence" begin
    s = "*not bold `because verbatim* has higher precedence`"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    for n in first(children(ps), 5)
        @test kind(n) == K"WordNode"
    end
    @test kind(last(children(ps))) == K"InlineCode"
end

@testset "Escaping is allowed in inline code" begin
    s = "`\\` still verbatim`"
    ast = parse(Norg.AST.NorgDocument, s)
    ps = first(children(first(children(ast))))
    @test length(children(ps)) == 1
    @test kind(first(children(ps))) == K"InlineCode"
end

@testset "Line endings are allowed withing attached modifiers." begin
    s = "/italic\ntoo/"
    ast = parse(Norg.AST.NorgDocument, s)
    p = first(children(ast))
    ps = first(children(p))
    @test length(children(ps)) == 1
    it = first(children(ps))
    @test kind(it) == K"Italic"
end

@testset "Precedence torture test." begin
    s = "test `1.`/`1)`, Norg \ntest"
    ast = parse(Norg.AST.NorgDocument, s)
    ps1, ps2 = children(first(children(ast)))
    @test kind(ps1) == K"ParagraphSegment"
    @test kind(ps2) == K"ParagraphSegment"
    ic1 = children(ps1)[3]
    ic2 = children(ps1)[5]
    @test kind(ic1) == K"InlineCode"
    @test kind(ic2) == K"InlineCode"
end
