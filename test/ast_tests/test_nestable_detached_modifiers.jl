
Node = Norg.AST.Node
AST = Norg.AST

nestable = [('-', AST.UnorderedList)
            ('~', AST.OrderedList)
            ('>', AST.Quote)]

@testset "$T should be grouping." for (m, T) in nestable
    s = """$m first item
    $m second item
    """
    ast = parse(AST.NorgDocument, s)
    nest = first(children(ast))
    @test nest isa Node{T{1}}
    item1, item2 = children(nest)
    @test item1 isa Node{AST.Paragraph}
    @test item2 isa Node{AST.Paragraph}
end

@testset "$T grouping should not happen when there is a paragraph break." for (m, T) in nestable
    s = """$m first item

    $m second item
    """
    ast = parse(AST.NorgDocument, s)
    nest1, nest2 = children(ast)
    @test nest1 isa Node{T{1}}
    @test nest2 isa Node{T{1}}
    item1 = first(children(nest1))
    @test item1 isa Node{AST.Paragraph}
    item2 = first(children(nest2))
    @test item2 isa Node{AST.Paragraph}
end

@testset "$T should be nestable." for (m, T) in nestable
    s = """$m item1
    $m$m subitem1
    $m$m subitem2
    $m item2
    """
    ast = parse(AST.NorgDocument, s)
    nest = first(children(ast))
    @test nest isa Node{T{1}}
    item1, nested, item2 = children(nest)
    @test item1 isa Node{AST.Paragraph}
    @test item2 isa Node{AST.Paragraph}
    @test nested isa Node{T{2}}
    subitem1, subitem2 = children(nested)
    @test subitem1 isa Node{AST.Paragraph}
    @test subitem2 isa Node{AST.Paragraph}
end

@testset "$T of level $i" for (m, T) in nestable, i in 1:6
    s = "$(repeat(m, i)) item"
    ast = parse(AST.NorgDocument, s)
    nest = first(children(ast))
    @test nest isa Node{T{i}}
end

@testset "Structural modifiers have higher precedence than $T" for (m, T) in nestable
    s = """$m item1
    * Not in item1
    """
    ast = parse(AST.NorgDocument, s)
    nest, h1 = children(ast)
    @test nest isa Node{T{1}}
    @test h1 isa Node{AST.Heading{1}}
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
    ast = parse(AST.NorgDocument, s)
    nest, h1, h1bis = children(ast)
    @test nest isa Node{T{1}}
    @test h1 isa Node{AST.Heading{1}}
    @test h1bis isa Node{AST.Heading{1}}
end
