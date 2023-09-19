AST = Norg.AST

@testset "simple verbatim" begin
    s = """@code
    hey
    @end
    """
    ast = norg(s)
    verb = first(children(ast.root))
    @test kind(verb) == K"Verbatim"
    @test length(children(verb)) == 2
    verb_body = last(children(verb))
    @test kind(verb_body) == K"VerbatimBody"
    @test AST.litteral(ast, verb_body) == "hey\n"
end

@testset "Test verbatim subtag" begin
    s = """@document.meta
    title: test document
    authors: [
    klafyvel
    ]
    version: 1.0
    @end
    """
    ast = norg(s)
    verb = first(children(ast.root))
    tag, subtag, _ = children(verb)
    @test AST.litteral(ast, tag) == "document"
    @test AST.litteral(ast, subtag) == "meta"
end

@testset "Test verbtatim with parameters" begin
    s = """@code julia
    println("hey you")
    @end
    """
    ast = norg(s)
    verb = first(children(ast.root))
    tag, lang, _ = children(verb)
    @test AST.litteral(ast, tag) == "code"
    @test AST.litteral(ast, lang) == "julia"
end

@testset "Test verbtatim with indentation" begin
    s = """    @code julia
    println("hey you")
        @end
    """
    ast = norg(s)
    verb = first(children(ast.root))
    tag, lang, _ = children(verb)
    @test AST.litteral(ast, tag) == "code"
    @test AST.litteral(ast, lang) == "julia"
end

@testset "Complex verbatim tag" begin
    s = """@verbatim.subtag beep bop i\\ am\\ parameter
    bla
    @end
    outside verbatim
    """
    ast = norg(s)
    verb, p = children(ast.root)
    tag, subtag, beep, bop, p, body = children(verb)
    @test AST.litteral(ast, tag) == "verbatim"
    @test AST.litteral(ast, subtag) == "subtag"
    @test AST.litteral(ast, beep) == "beep"
    @test AST.litteral(ast, bop) == "bop"
    # TODO: this is a bit annoying to work with, but I will provide some utility
    # functions to work with ranged tag parameters anyway, so I can make them
    # treat the escape characters better.
    @test AST.litteral(ast, p) == "i\\ am\\ parameter"
    @test AST.litteral(ast, body) == "bla\n"
end

@testset "Verbatim in a paragraph" begin
    s = """Some markup is allowed within:
    @code java
    @MyAnnotation(name="someName", value="Hello World")
    public class TheClass {
      // ...
    }
    @end
    """
    ast = norg(s)
    p, verb = children(ast.root)
    @test kind(p) == K"Paragraph"
    @test kind(verb) == K"Verbatim"
end

@testset "Verbatim in a heading" begin
    s = """* heading
    @code java
    @MyAnnotation(name="someName", value="Hello World")
    public class TheClass {
      // ...
    }
    @end
    """
    ast = norg(s)
    h1 = first(children(ast.root))
    h1_title, verb = children(h1)
    @test kind(h1_title) == K"ParagraphSegment"
    @test kind(verb) == K"Verbatim"
end

tagtypes = [
    ("+", K"WeakCarryoverTag")
    ("@", K"Verbatim")
]

@testset "Tag names with punctuation" begin
    ast = norg"""
    +example-tag
    hey
    """
    t = first(children(first(children(ast.root))))
    @test kind(t) == K"WeakCarryoverTag"
    tagname, _... = children(t)
    @test Norg.Codegen.textify(ast, tagname) == "example-tag"
    ast = norg"""
    #example-tag
    hey
    """
    t = first(children(ast.root))
    @test kind(t) == K"StrongCarryoverTag"
    tagname, _... = children(t)
    @test Norg.Codegen.textify(ast, tagname) == "example-tag"
    ast = norg"""
    @example-tag
    hi
    @end
    """
    t = first(children(ast.root))
    @test kind(t) == K"Verbatim"
    tagname, _... = children(t)
    @test Norg.Codegen.textify(ast, tagname) == "example-tag"
end

@testset "Weak carryover tag applies to the right elements." begin
    @testset "Paragraghs and paragraph segments." begin
        ast = norg"""
        +test
        Applied here.
        Not applied here.
        """
        p = first(children(ast.root))
        t, ps = children(p)
        @test kind(t) == K"WeakCarryoverTag"
        @test kind(ps) == K"ParagraphSegment"
        label, ps = children(t)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test Norg.Codegen.textify(ast, ps) == "Applied here."
        ast = norg"""
        Not applied here.
        +test
        Applied here.
        """
        p = first(children(ast.root))
        ps, t = children(p)
        @test kind(t) == K"WeakCarryoverTag"
        @test kind(ps) == K"ParagraphSegment"
        label, ps = children(t)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test Norg.Codegen.textify(ast, ps) == "Applied here."
    end
    nestables = [("-", K"UnorderedList1"), ("~", K"OrderedList1"), (">", K"Quote1")]
    @testset "Nestable modifiers: $m" for (t, m) in nestables
        s = """
        +test
        $t applied
        $t not applied
        """
        ast = norg(s)
        nestable = first(children(ast.root))
        tag, item = children(nestable)
        @test kind(tag) == K"WeakCarryoverTag"
        @test kind(item) == K"NestableItem"
        @test Norg.Codegen.textify(ast, item) == "not applied"
        label, item = children(tag)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test Norg.Codegen.textify(ast, item) == "applied"
        s = """
        $t not applied
        +test
        $t applied
        """
        ast = norg(s)
        nestable = first(children(ast.root))
        item, tag = children(nestable)
        @test kind(tag) == K"WeakCarryoverTag"
        @test kind(item) == K"NestableItem"
        @test Norg.Codegen.textify(ast, item) == "not applied"
        label, item = children(tag)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test Norg.Codegen.textify(ast, item) == "applied"
    end
    various = [
        (
            """
           +test
           * Heading
           hi there
           """,
            K"Heading1",
        )
        (
            """
           +test
           @test 
           blip
           @end
           """,
            K"Verbatim",
        )
    ]
    @testset "Various child kind: $k" for (s, k) in various
        ast = norg(s)
        tag = first(children(ast.root))
        @test kind(tag) == K"WeakCarryoverTag"
        label, child = children(tag)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test kind(child) == k
    end
end

@testset "Strong carryover tag applies to the right elements." begin
    @testset "Paragraghs and paragraph segments." begin
        ast = norg"""
        #test
        Applied here.
        Applied here too.
        """
        t = first(children(ast.root))
        @test length(children(t)) == 2
        label, p = children(t)
        @test kind(t) == K"StrongCarryoverTag"
        @test kind(p) == K"Paragraph"
        @test Norg.Codegen.textify(ast, label) == "test"
        ast = norg"""
        Not applied here.
        #test
        Applied here.
        """
        p1, t = children(ast.root)
        @test kind(t) == K"StrongCarryoverTag"
        @test kind(p1) == K"Paragraph"
        label, p2 = children(t)
        @test kind(p2) == K"Paragraph"
        @test Norg.Codegen.textify(ast, label) == "test"
        @test Norg.Codegen.textify(ast, p2) == "Applied here."
    end
    nestables = [("-", K"UnorderedList1"), ("~", K"OrderedList1"), (">", K"Quote1")]
    @testset "Nestable modifiers: $m" for (t, m) in nestables
        s = """
        #test
        $t applied
        $t applied
        """
        ast = norg(s)
        tag = first(children(ast.root))
        @test kind(tag) == K"StrongCarryoverTag"
        @test length(children(tag)) == 2
        nestable = last(children(tag))
        @test kind(nestable) == m
        for item in children(nestable)
            @test kind(item) == K"NestableItem"
            @test Norg.Codegen.textify(ast, item) == "applied"
        end
        label = first(children(tag))
        @test Norg.Codegen.textify(ast, label) == "test"
        s = """
        $t not applied
        #test
        $t applied
        """
        ast = norg(s)
        nestable, tag = children(ast.root)
        @test kind(tag) == K"StrongCarryoverTag"
        @test kind(nestable) == m
        @test kind(first(children(nestable))) == K"NestableItem"
        @test Norg.Codegen.textify(ast, nestable) == "not applied"
        label, nestable = children(tag)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test kind(nestable) == m
        @test kind(first(children(nestable))) == K"NestableItem"
        @test Norg.Codegen.textify(ast, nestable) == "applied"
    end
    various = [
        (
            """
           #test
           * Heading
           hi there
           """,
            K"Heading1",
        )
        (
            """
           #test
           @test 
           blip
           @end
           """,
            K"Verbatim",
        )
    ]
    @testset "Various child kind: $k" for (s, k) in various
        ast = norg(s)
        tag = first(children(ast.root))
        @test kind(tag) == K"StrongCarryoverTag"
        label, child = children(tag)
        @test Norg.Codegen.textify(ast, label) == "test"
        @test kind(child) == k
    end
end

standard_children = [
    (K"Heading1", "* content")
    (K"UnorderedList1", "- content")
    (K"OrderedList1", "~ content")
    (K"Quote1", "> content")
    (K"Paragraph", "content")
]
@testset "Standard Ranged-tag children: $T" for (T, content) in standard_children
    s = """|example
    $content
    |end
    """
    ast = norg(s)
    @test length(children(ast.root)) == 1
    tag = first(children(ast.root))
    @test kind(tag) == K"StandardRangedTag"
    @test length(children(tag)) == 2
    body = last(children(tag))
    @test length(children(body)) == 1
    @test kind(last(children(body))) == T
end
