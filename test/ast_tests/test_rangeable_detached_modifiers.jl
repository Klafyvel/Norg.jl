Node = Norg.AST.Node
AST = Norg.AST
textify = Norg.Codegen.textify

rangeable = [
    ('$', K"Definition")
    ('^', K"Footnote")
]

@testset "Single paragraph rangeable: $T" for (m, T) in rangeable
    s = """$m title
    funny content

    outside
    """
    ast = parse(AST.NorgDocument, s)
    rang,p = children(ast)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content) == "funny content"
end

@testset "multiple paragraph rangeable: $T" for (m, T) in rangeable
    s = """$m$m title
    funny content1

    funny content2
    $m$m
    outside
    """
    ast = parse(AST.NorgDocument, s)
    rang,p = children(ast)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content1,content2 = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content1) == K"Paragraph"
    @test kind(content2) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content1) == "funny content1"
    @test textify(ast, content2) == "funny content2"
end

@testset "Single paragraph rangeable within title: $T" for (m, T) in rangeable
    s = """* test
    $m title
    funny content

    outside
    """
    ast = parse(AST.NorgDocument, s)
    t = first(children(ast))
    _,rang,p = children(t)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content) == "funny content"
end

@testset "multiple paragraph rangeable within title: $T" for (m, T) in rangeable
    s = """* test
    $m$m title
    funny content1

    funny content2
    $m$m
    outside
    """
    ast = parse(AST.NorgDocument, s)
    t = first(children(ast))
    _,rang,p = children(t)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content1,content2 = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content1) == K"Paragraph"
    @test kind(content2) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content1) == "funny content1"
    @test textify(ast, content2) == "funny content2"
end

@testset "Single paragraph rangeable with weird indentation: $T" for (m, T) in rangeable
    s = """    $m title
    funny content

    outside
    """
    ast = parse(AST.NorgDocument, s)
    rang,p = children(ast)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content) == "funny content"
end

@testset "multiple paragraph with weir indentationrangeable: $T" for (m, T) in rangeable
    s = """    $m$m title
    funny content1

    funny content2
        $m$m
    outside
    """
    ast = parse(AST.NorgDocument, s)
    rang,p = children(ast)
    @test kind(rang) == T
    @test kind(p) == K"Paragraph"
    @test textify(ast, p) == "outside"
    item = first(children(rang))
    @test kind(item) == K"RangeableItem"
    title,content1,content2 = children(item)
    @test kind(title) == K"ParagraphSegment"
    @test kind(content1) == K"Paragraph"
    @test kind(content2) == K"Paragraph"
    @test textify(ast, title) == "title"
    @test textify(ast, content1) == "funny content1"
    @test textify(ast, content2) == "funny content2"
end

@testset "Rangeables must be grouping: $T" for (m, T) in rangeable
    make_str(str_kind, label) = if str_kind=="simple"
        """$m title$(label)
        content$(label)
        """
    else
        """$m$m title$(label)
        content$(label)
        $m$m
        """
    end
    for a in ("simple", "matched")
        s_a = make_str(a, "a")
        for b in ("simple", "matched")
            s_b = make_str(b, "b")
            for c in ("simple", "matched")
                s_c = make_str(c, "c")
                s = s_a*s_b*s_c
                ast = parse(AST.NorgDocument, s)
                rang = first(children(ast))
                @test kind(rang) == T
                for (l,item) in zip(["a", "b", "c"], children(rang))
                    @test kind(item) === K"RangeableItem"
                    title, content = children(item)
                    @test textify(ast, title) == "title$l"
                    @test textify(ast, content) == "content$l"
                end
            end
        end
    end
end
