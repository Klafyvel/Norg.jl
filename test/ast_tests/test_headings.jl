# model : https://github.com/nvim-neorg/tree-sitter-norg/blob/main/test/corpus/headings.txt

Node = Norg.AST.Node

@testset "Level 1 heading" begin
    s = """* This is a heading
      In this heading there is some text
      ===

    This is no longer part of the heading."""

    ast = norg(s)

    h1,sd,p = children(ast)

    @test kind(h1) == K"Heading1"
    @test kind(p) == K"Paragraph"
    @test kind(sd) == K"StrongDelimitingModifier"

    h1_title, h1_par = children(h1)
    @test kind(h1_title) == K"ParagraphSegment"
    @test length(children(h1_title)) == 7
    @test kind(h1_par) == K"Paragraph"
end

heading_levels = 2:6

@testset "Level $i heading" for i in heading_levels
    s = """$(repeat("*", i)) This is a level $i heading
   That has text underneath

* And here is a level 1 heading
"""

    for j in 2:i
        s_j = """$(repeat("*", j)) With a level $i heading
     And some content
     """
        s *= s_j
    end
    s *= """===

And here is some more text that has broken out of the matrix.
"""

    ast = norg(s)

    hi = first(children(ast))
    h1 = children(ast)[2]
    p = last(children(ast))

    @test kind(hi) == AST.heading_level(i)
    @test kind(h1) == K"Heading1"
    @test kind(p) == K"Paragraph"

    hi_title = first(children(hi))
    @test kind(hi_title) == K"ParagraphSegment"
    @test length(children(hi_title)) == 11

    hj = children(h1)[2]
    for j in 2:i
        @test kind(hj) == AST.heading_level(j)
        hj_title = first(children(hj))
        @test kind(hj_title) == K"ParagraphSegment"
        @test length(children(hj_title)) == 9

        hj_par = children(hj)[2]
        @test kind(hj_par) == K"Paragraph"
        hj = last(children(hj))
    end
end

@testset "Indentation reversion" begin
    s = """Time to test indentation reversion.

    * This is a heading
      ** It contains a level 2 heading
         Which in turn contains some text.
         ---
      This should reverse the indentation and
      it should be part of the first-level
      heading now
      *** This is now a third-level heading
          ---
      And it has reversed too
      *** Another third-level heading
      ===

    This should no longer be part of the heading."""

    ast = norg(s)

    p1, h1, strong_delimiter, p2 = children(ast)

    @test kind(p1) == K"Paragraph"
    @test kind(h1) == K"Heading1"
    @test kind(strong_delimiter) == K"StrongDelimitingModifier"
    @test kind(p2) == K"Paragraph"

    h1_title, h2, p1, h3, p2, h3bis = children(h1)
    @test kind(h1_title) == K"ParagraphSegment"
    @test kind(h2) == K"Heading2"
    @test kind(p1) == K"Paragraph"
    @test kind(h3) == K"Heading3"
    @test kind(p2) == K"Paragraph"
    @test kind(h3bis) == K"Heading3"

    h2_title, p, weak_delimiter = children(h2)
    @test kind(h2_title) == K"ParagraphSegment"
    @test kind(p) == K"Paragraph"
    @test kind(weak_delimiter) == K"WeakDelimitingModifier"
end

@testset "Malformed indentation reversion" begin
    s = """* Heading
    A paragraph
    --- 
    This should not be reverted since the previous element
    has whitespace afterwards.
    It should instead be treated as an unordered list element.

    This --- should also not revert the heading.
    --neither- should this
    ---

    This should though."""

    ast = norg(s)

    h1, p = children(ast)
    @test kind(h1) == K"Heading1"
    @test kind(p) == K"Paragraph"
end

@testset "Horizontal line" begin
    s = """This is some text.
___
Separated by a horizontal line."""

    ast = norg(s)
    p1, hr, p2 = children(ast)
    @test kind(p1) == K"Paragraph"
    @test kind(hr) == K"HorizontalRule"
    @test kind(p2) == K"Paragraph"
end

@testset "Horizontal line in a heading" begin
    s = """
           * Heading level 1
             Text under first level heading.
             ___
             This is a new paragraph separated from the previous one by a horizontal
             """
    ast = norg(s)
    h1 = first(children(ast))
    h1_title, p1, hr, p2 = children(h1)
    @test kind(p1) == K"Paragraph"
    @test kind(hr) == K"HorizontalRule"
    @test kind(p2) == K"Paragraph"
end

@testset "Delimiting modifiers should not be too greedy.: $m" for m in ("=", "-", "_")
    ast = norg("""Hello
    $m$m$m
    There
    """)
    p1,delim,p2 = children(ast)
    @test Norg.Codegen.textify(ast, p1) == "Hello"
    @test Norg.Codegen.textify(ast, p2) == "There"
end
