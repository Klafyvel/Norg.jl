# model : https://github.com/nvim-neorg/tree-sitter-norg/blob/main/test/corpus/headings.txt

Node = Norg.AST.Node

@testset "Level 1 heading" begin
s = """* This is a heading
  In this heading there is some text
  ===

This is no longer part of the heading."""

ast = parse(Norg.AST.NorgDocument, s)

h1 = first(children(ast))
p = last(children(ast))

@test h1 isa Node{Norg.AST.Heading{1}}
@test p isa Node{Norg.AST.Paragraph}

h1_title = nodevalue(h1).title 
@test h1_title isa Node{Norg.AST.ParagraphSegment}
@test length(children(h1_title)) == 7

h1_par = first(children(h1))
@test h1_par isa Node{Norg.AST.Paragraph}

end

heading_levels = 2:6

@testset "Level $i heading" for i ∈ heading_levels 
    s = """$(repeat("*", i)) This is a level $i heading
   That has text underneath

* And here is a level 1 heading
"""

    for j ∈ 2:i 
        s_j = """$(repeat("*", j)) With a level $i heading
     And some content
     """
        s *= s_j 
    end
     s *= """===

And here is some more text that has broken out of the matrix.
"""

ast = parse(Norg.AST.NorgDocument, s)

hi = first(children(ast))
h1 = children(ast)[2]
p = last(children(ast))

@test hi isa Node{Norg.AST.Heading{i}}
@test h1 isa Node{Norg.AST.Heading{1}}
@test p isa Node{Norg.AST.Paragraph}

    hi_title = nodevalue(hi).title
    @test hi_title isa Node{Norg.AST.ParagraphSegment}
    @test length(children(hi_title)) == 11

hj = first(children(h1))
for j ∈ 2:i 
    @test hj isa Node{Norg.AST.Heading{j}}
    hj_title = nodevalue(hj).title
    @test hj_title isa Node{Norg.AST.ParagraphSegment}
    @test length(children(hj_title)) == 9

    hj_par = first(children(hj))
    @test hj_par isa Node{Norg.AST.Paragraph}
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

ast = parse(Norg.AST.NorgDocument, s)

p1, h1, p2 = children(ast)

@test p1 isa Node{Norg.AST.Paragraph}
@test h1 isa Node{Norg.AST.Heading{1}}
@test p2 isa Node{Norg.AST.Paragraph}

h2, p1, h3, p2, h3bis = children(h1)
@test h2 isa Node{Norg.AST.Heading{2}}
@test p1 isa Node{Norg.AST.Paragraph}
@test h3 isa Node{Norg.AST.Heading{3}}
@test p2 isa Node{Norg.AST.Paragraph}
@test h3bis isa Node{Norg.AST.Heading{3}}

p = first(children(h2))
@test p isa Node{Norg.AST.Paragraph}
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

ast = parse(Norg.AST.NorgDocument, s)

h1, p = children(ast)
@test h1 isa Node{Norg.AST.Heading{1}}
@test p isa Node{Norg.AST.Paragraph}
end

@testset "Horizontal line" begin
    s = """This is some text.
___
Separated by a horizontal line."""

ast = parse(Norg.AST.NorgDocument, s)
p1, hr, p2 = children(ast)
@test p1 isa Node{Norg.AST.Paragraph}
@test hr isa Node{Norg.AST.HorizontalRule}
@test p2 isa Node{Norg.AST.Paragraph}
end
