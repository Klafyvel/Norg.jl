
Node = Norg.AST.Node
AST = Norg.AST

nestable = [
    ('-', K"UnorderedList1")
    ('~', K"OrderedList1")
    ('>', K"Quote1")
]

@testset "$T should be grouping." for (m, T) in nestable
    s = """$m first item
    $m second item
    """
    ast = norg(s)
    nest = first(children(ast.root))
    @test kind(nest) == T
    item1, item2 = children(nest)
    @test kind(item1) == K"NestableItem"
    @test kind(item2) == K"NestableItem"
end

@testset "$T grouping should not happen when there is a paragraph break." for (m, T) in
                                                                              nestable
    s = """$m first item

    $m second item
    """
    ast = norg(s)
    nest1, nest2 = children(ast.root)
    @test kind(nest1) == T
    @test kind(nest2) == T
    item1 = first(children(nest1))
    @test kind(item1) == K"NestableItem"
    item2 = first(children(nest2))
    @test kind(item2) == K"NestableItem"
end

nestable_check = [
    ('-', AST.is_unordered_list)
    ('~', AST.is_ordered_list)
    ('>', AST.is_quote)
]

@testset "$m should be nestable." for (m, verif) in nestable_check
    s = """$m item1
    $m$m subitem1
    $m$m subitem2
    $m item2
    """
    ast = norg(s)
    nest = first(children(ast.root))
    @test verif(nest)
    item1, item2 = children(nest)
    @test kind(item1) == K"NestableItem"
    @test kind(item2) == K"NestableItem"
    nested = last(children(item1))
    @test verif(nested)
    subitem1, subitem2 = children(nested)
    @test kind(subitem1) == K"NestableItem"
    @test kind(subitem2) == K"NestableItem"
end

nestable_level_check = [
    ('-', Norg.AST.unordered_list_level)
    ('~', Norg.AST.ordered_list_level)
    ('>', Norg.AST.quote_level)
]
@testset "$T of level $i" for (m, T) in nestable_level_check, i in 1:6
    s = "$(repeat(m, i)) item"
    ast = norg(s)
    nest = first(children(ast.root))
    @test kind(nest) == T(i)
end

@testset "Structural modifiers have higher precedence than $T" for (m, T) in nestable
    s = """$m item1
    * Not in item1
    """
    ast = norg(s)
    nest, h1 = children(ast.root)
    @test kind(nest) == T
    @test kind(h1) == K"Heading1"
end

@testset "Complicated example of $T" for (m, T) in nestable
    s = """
      $m I am a lonesome $T.
      $m sigh
      yes you can multiple paragraph segments.
      * Heading
      $m List
      $m List
      still in the $T
      $m$m In the $T and at a higher level
      $m$m$m Wait
      $m$m$m$m What are you trying to do here ?
      $m$m$m$m$m Going higher ?
      $m$m$m$m$m$m Ah, I see.
      $m$m$m$m$m$m$m Did you really think you were going to break something here ?
      Still there btw
      $m In the first $T
      * But $(T)s have to behave, for a heading shall break them.
      """
    ast = norg(s)
    nest, h1, h1bis = children(ast.root)
    @test kind(nest) == T
    @test kind(h1) == K"Heading1"
    @test kind(h1bis) == K"Heading1"
end

@testset "Nestable delimiter within paragraphs" begin
    s = """** Paragraphs
          Paragraphs are then formed of consecutive {** paragraph segments}. A paragraph is terminated by:
          - A <paragraph break> (two consecutive {# line ending}s)
          - Any of the {* detached modifiers}
          - Any of the {** delimiting modifiers}
          - Any of the {** ranged tags}
          - Any of the {*** strong carryover tags}
       """
    ast = norg(s)
    title, p, ul = children(first(children(ast.root)))
    @test kind(title) == K"ParagraphSegment"
    @test kind(p) == K"Paragraph"
    @test kind(ul) == K"UnorderedList1"
end
