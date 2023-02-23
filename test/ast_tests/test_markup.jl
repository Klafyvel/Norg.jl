# model : https://github.com/nvim-neorg/tree-sitter-norg/blob/dev/test/corpus/markup.txt

Node = Norg.AST.Node
AST = Norg.AST
textify = Norg.Codegen.textify

simple_markups = [
("*", K"Bold"),
("/", K"Italic") ,
("_", K"Underline"),
("-", K"Strikethrough"),
("!", K"Spoiler"),
("^", K"Superscript"),
(",", K"Subscript"),
("`", K"InlineCode"),
("%", K"NullModifier"),
("\$", K"InlineMath"),
("&", K"Variable")
]

@testset "Standalone markup for $m" for (m,k) in simple_markups
    ast = norg("$(m)inner$(m)")
    @test ast isa Norg.AST.NorgDocument
    p = first(children(ast.root))
    @test kind(p) == K"Paragraph"
    ps = first(children(p))
    @test kind(ps) == K"ParagraphSegment"
    marknode = first(children(ps))
    @test kind(marknode) == k
    ps = first(children(marknode))
    @test kind(ps) == K"ParagraphSegment"
    w = first(children(ps))
    @test kind(w) == K"WordNode"
    @test join(Norg.Tokens.value.(ast.tokens[w.start:w.stop])) == "inner"
end

@testset "Markup inside a sentence for $m" for (m, k) in simple_markups
    ast = norg("When put inside a sentence $(m)inner$(m).")
    @test ast isa Norg.AST.NorgDocument
    p = first(children(ast.root))
    @test kind(p) == K"Paragraph"
    ps = first(children(p))
    @test kind(ps) == K"ParagraphSegment"
    marknode = children(ps)[11]
    @test kind(marknode) == k
    ps = first(children(marknode))
    @test kind(ps) == K"ParagraphSegment"
    w = first(children(ps))
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
    ('%', K"NullModifier"),
]

@testset "Nested markup $n inside $m" for (m, T) in simple_nested_outer,
                                          (n, U) in simple_markups
    if m == n
        continue
    end
    s = "$(m)Nested $(n)inner$(n)$(m)"
    ast = norg(s)
    outernode = first(children(first(children(first(children(ast.root))))))
    @test kind(outernode) == T
    ps = first(children(outernode))
    @test kind(ps) == K"ParagraphSegment"
    innernode = last(children(ps))
    @test kind(innernode) == U
    ps = first(children(innernode))
    @test kind(ps) == K"ParagraphSegment"
    w = first(children(ps))
    @test kind(w) == K"WordNode"
    @test join(Norg.Tokens.value.(ast.tokens[w.start:w.stop])) == "inner"
end

verbatim_nested = [
    ("`", K"InlineCode"),
    ("\$", K"InlineMath"),
    ("&", K"Variable")
]

@testset "Verbatim markup nesting test: $V" for (v,V) in verbatim_nested
    @testset "Nested markup $T inside $V" for (m, T) in simple_markups
        if occursin(m, "`\$&")
            continue
        end
        s = "$(v)Nested $(m)inner$(m)$(v)"
        ast = norg(s)
        outernode = first(children(first(children(first(children(ast.root))))))
        @test kind(outernode) == V
        ps = first(children(outernode))
        @test kind(ps) == K"ParagraphSegment"
        for n in children(ps)
            @test kind(n) == K"WordNode"
        end
    end
end

@testset "Escaping modifier $m" for (m, _) in simple_markups
    s = "This is \\$(m)normal\\$(m)"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    for n in children(ps)
        @test kind(n) ∈ [K"Escape", K"WordNode"]
    end
end

@testset "No empty modifier $m" for (m, T) in simple_markups
    s = "nothing to see $(m)$(m) here"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    for n in children(ps)
        @test kind(n) == K"WordNode"
    end
end

@testset "First closing modifier has precedence" begin
    s = "*first bold* some /italic/ and not bold*"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    b = children(ps)[1]
    i = children(ps)[5]
    @test kind(b) == K"Bold"
    @test kind(i) == K"Italic"
end

@testset "First closing modifier has precedence" begin
    s = "*This /is bold*/"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    b = children(ps)[1]
    @test kind(b) == K"Bold"
end

@testset "Yet another precedence test." begin
    s = "*/Bold and italic*/"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    b,w = children(ps)
    @test kind(b) == K"Bold"
    @test kind(w) == K"WordNode"
    ps = first(children(b))
    for c in children(ps)
        @test kind(c) == K"WordNode"
    end
end

@testset "Verbatim precedence" begin
    s = "*not bold `because verbatim* has higher precedence`"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    for n in first(children(ps), 5)
        @test kind(n) == K"WordNode"
    end
    @test kind(last(children(ps))) == K"InlineCode"
end

# TODO: this is actually not in the spec, but useful while layer 4 is not implemented.
@testset "Escaping is allowed in inline code" begin
    s = "`\\` still verbatim`"
    ast = norg(s)
    ps = first(children(first(children(ast.root))))
    @test length(children(ps)) == 1
    @test kind(first(children(ps))) == K"InlineCode"
end

@testset "Line endings are allowed withing attached modifiers." begin
    s = "/italic\ntoo/"
    ast = norg(s)
    p = first(children(ast.root))
    ps = first(children(p))
    @test length(children(ps)) == 1
    it = first(children(ps))
    @test kind(it) == K"Italic"
end

@testset "Precedence torture test." begin
    s = "test `1.`/`1)`, Norg \ntest"
    ast = norg(s)
    ps1, ps2 = children(first(children(ast.root)))
    @test kind(ps1) == K"ParagraphSegment"
    @test kind(ps2) == K"ParagraphSegment"
    ic1 = children(ps1)[3]
    ic2 = children(ps1)[5]
    @test kind(ic1) == K"InlineCode"
    @test kind(ic2) == K"InlineCode"
end

@testset "Link modifier for: $T" for (m,T) in simple_markups
    ast = norg("Intra:$(m)word$(m):markup")
    ps = first(children(first(children(ast.root))))
    w1,mark,w2 = children(ps)
    @test kind(w1) == K"WordNode"
    @test kind(mark) == T
    @test kind(w2) == K"WordNode"
    @test textify(ast, w1) == "Intra"
    @test textify(ast, mark) == "word"
    @test textify(ast, w2) == "markup"
end
