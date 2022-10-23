AST = Norg.AST

@testset "simple verbatim" begin
    s = """@code
    hey
    @end
    """
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
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
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
    tag, subtag, _ = children(verb)
    @test AST.litteral(ast, tag) == "document"
    @test AST.litteral(ast, subtag) == "meta"
end

@testset "Test verbtatim with parameters" begin
    s = """@code julia
    println("hey you")
    @end
    """
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
    tag, lang, _ = children(verb)
    @test AST.litteral(ast, tag) == "code"
    @test AST.litteral(ast, lang) == "julia"
end

@testset "Test verbtatim with indentation" begin
    s = """    @code julia
    println("hey you")
        @end
    """
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
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
    ast = parse(AST.NorgDocument, s)
    verb, p = children(ast)
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
    ast = parse(AST.NorgDocument, s)
    p, verb = children(ast)
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
    ast = parse(AST.NorgDocument, s)
    h1 = first(children(ast))
    h1_title, verb = children(h1)
    @test kind(h1_title) == K"ParagraphSegment"
    @test kind(verb) == K"Verbatim"
end
