Node = Norg.AST.Node
AST = Norg.AST
textify = Norg.Codegen.textify

slide_children = [
    (K"Definition", """\$ Single definition
    Hello world""")
    (K"Definition", """\$\$ Longer definition
    Hello
    It's me
    \$\$""")
    (K"Definition", """\$ Grouped definition
    hey
    \$ Another one
    ho""")
    (K"Footnote", """^ Single footnote
    Hello world""")
    (K"Footnote", """^^ Longer footnote
    Hello
    It's me
    ^^""")
    (K"Footnote", """^ Grouped footnote
    hey
    ^ Another one
    ho""")
    (K"Verbatim", """@verb foo
    This is some very cody code.
    @end""")
    (K"Paragraph", """I'm a simple paragraph.
    Pretty unimpressive eh?""")
]

nestable = [('-', K"UnorderedList1")
            ('~', K"OrderedList1")
            ('>', K"Quote1")]

@testset "Slide can have $(child_T) children" for (child_T, child_text) in slide_children
    for (m,nestable_T) in nestable
        s = """$m First line
        $m :
        $(child_text)
        $m last line"""
        ast = norg(s)
        nest = first(children(ast))
        @test kind(nest) == nestable_T
        i1,i2,i3 = children(nest)
        @test kind(i1) == K"NestableItem"
        @test kind(i2) == K"NestableItem"
        @test kind(i3) == K"NestableItem"
        slide = first(children(i2))
        @test kind(slide) == K"Slide"
        c = first(children(slide))
        @test kind(c) == child_T
    end
end

@testset "Indent segments" begin
    @testset "Basic indent segment" begin
        ast = norg"""- ::
        This is a paragraph.

        This is another paragraph inside of the same list item.
        """
        ul = first(children(ast))
        @test kind(ul) == K"UnorderedList1"
        li = first(children(ul))
        @test kind(li) == K"NestableItem"
        is = first(children(li))
        @test kind(is) == K"IndentSegment"
        p1, p2 = children(is)
        @test kind(p1) == K"Paragraph"
        @test kind(p2) == K"Paragraph"
        @test textify(ast, p1) == "This is a paragraph."
        @test textify(ast, p2) == "This is another paragraph inside of the same list item."

    end
    @testset "Delimiter precendence in indent segment" begin
        ast = norg"""* Heading
        - ::
        Text
        ---
        This should still be part of the heading.
        """
        h1 = first(children(ast))
        @test kind(h1) == K"Heading1"
        title, ul, p = children(h1)
        @test textify(ast, title) == "Heading"
        @test kind(ul) == K"UnorderedList1"
        @test kind(p) == K"Paragraph"
        @test textify(ast, p) == "This should still be part of the heading."
        li = first(children(ul))
        @test kind(li) == K"NestableItem"
        is = first(children(li))
        @test kind(is) == K"IndentSegment"
        p,wd = children(is)
        @test kind(wd) == K"WeakDelimitingModifier"
        @test kind(p) == K"Paragraph"
        @test textify(ast, is) == "Text"
    end
    @testset "Nested indent segment" begin
        ast = norg"""- ::
        This is an indent segment.

        This paragraph should also belong to the indent segment.

        -- ::
        This is now part of the second indent segment.

        @code lua
        print("Hello!")
        @end
        ===

        This is not a part of any indent segment.
        """
        ul,sd,p = children(ast)
        @test kind(ul) == K"UnorderedList1"
        @test kind(sd) == K"StrongDelimitingModifier"
        @test kind(p) == K"Paragraph"
        @test textify(ast, p) == "This is not a part of any indent segment."
        is = first(children(first(children(ul))))
        @test kind(is) == K"IndentSegment"
        p1,p2,ul = children(is)
        @test kind(p1) == K"Paragraph"
        @test kind(p2) == K"Paragraph"
        @test textify(ast, p1) == "This is an indent segment."
        @test textify(ast, p2) == "This paragraph should also belong to the indent segment."
        @test kind(ul) == K"UnorderedList2"
        is = first(children(first(children(ul))))
        p,verb = children(is)
        @test kind(p) == K"Paragraph"
        @test kind(verb) == K"Verbatim"
    end
end
