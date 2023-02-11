Node = Norg.AST.Node
AST = Norg.AST

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
        ast = parse(AST.NorgDocument, s)
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
