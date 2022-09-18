# model : https://github.com/nvim-neorg/tree-sitter-norg/blob/dev/test/corpus/markup.txt

Node = Norg.AST.Node

simple_markups = [
    ('*', Norg.AST.Bold),
    ('/', Norg.AST.Italic),
    ('_', Norg.AST.Underline),
    ('-', Norg.AST.Strikethrough),
    ('!', Norg.AST.Spoiler),
    ('^', Norg.AST.Superscript),
    (',', Norg.AST.Subscript),
    ('`', Norg.AST.InlineCode),
]

@testset "Standalone markup for $m" for (m, T) in simple_markups
    ast = parse(Norg.AST.NorgDocument, "$(m)inner$(m)")
    nodes = collect(PreOrderDFS(ast))
    @test nodes[1] isa Node{Norg.AST.NorgDocument}
    @test nodes[2] isa Node{Norg.AST.Paragraph}
    @test nodes[3] isa Node{Norg.AST.ParagraphSegment}
    @test nodes[4] isa Node{T}
    @test nodes[5] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[5]).value == "inner"
end

@testset "Markup inside a sentence for $m" for (m, T) in simple_markups
    ast = parse(Norg.AST.NorgDocument,
                "When put inside a sentence $(m)inner$(m).")
    nodes = collect(PreOrderDFS(ast))
    @test nodes[14] isa Node{T}
    @test nodes[15] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[15]).value == "inner"
    @test nodes[16] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[16]).value == "."
end

simple_nested_outer = [
    ('*', Norg.AST.Bold),
    ('/', Norg.AST.Italic),
    ('_', Norg.AST.Underline),
    ('-', Norg.AST.Strikethrough),
    ('!', Norg.AST.Spoiler),
    ('^', Norg.AST.Superscript),
    (',', Norg.AST.Subscript),
]

@testset "Nested markup $n inside $m" for (m, T) in simple_nested_outer,
                                          (n, U) in simple_markups

    if m == n
        continue
    end
    s = "$(m)Nested $(n)inner$(n)$(m)"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{T}
    @test nodes[7] isa Node{U}
    @test nodes[8] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[8]).value == "inner"
end

@testset "Nested markup $m inside `" for (m, T) in simple_markups
    if m == '`'
        continue
    end
    s = "`Nested $(m)inner$(m)`"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.InlineCode}
    @test nodes[7] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[7]).value == string(m)
    @test nodes[8] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[8]).value == "inner"
    @test nodes[9] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[9]).value == string(m)
end

@testset "Escaping modifier $m" for (m, _) in simple_markups
    s = "This is \\$(m)normal\\$(m)"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[8] isa Node{Norg.AST.Escape}
    @test nodevalue(nodes[8]).value == string(m)
    @test nodes[9] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[9]).value == "normal"
    @test nodes[10] isa Node{Norg.AST.Escape}
    @test nodevalue(nodes[10]).value == string(m)
end

@testset "No empty modifier $m" for (m, T) in simple_markups
    s = "nothing to see $(m)$(m) here"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test !any(isa.(nodes, Node{T}))
end

@testset "First closing modifier has precedence" begin
    s = "*first bold* some /italic/ and not bold*"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.Bold}
    @test nodes[5] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[5]).value == "first"
    @test nodes[11] isa Node{Norg.AST.Italic}
    @test nodes[12] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[12]).value == "italic"
    @test nodes[19] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[19]).value == "*"
end

@testset "First closing modifier has precedence" begin
    s = "*This /is bold*/"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.Bold}
end

@testset "Verbatim precedence" begin
    s = "*not bold `because verbatim* has higher precedence`"
    ast = parse(Norg.AST.NorgDocument, s)
    nodes = collect(PreOrderDFS(ast))
    @test nodes[4] isa Node{Norg.AST.Word}
    @test nodevalue(nodes[4]).value == "*"
    @test nodes[9] isa Node{Norg.AST.InlineCode}
end
