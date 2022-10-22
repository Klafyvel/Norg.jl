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
    @test join(AST.value.(ast.tokens[verb_body.start:verb_body.stop])) == "hey\n"
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
    @test nodevalue(verb).tag == "document"
    @test nodevalue(verb).subtag == "meta"
end

@testset "Test verbtatim with parameters" begin
    s = """@code julia
    println("hey you")
    @end
    """
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
    @test nodevalue(verb).parameters == ["julia"]
end

@testset "Test verbtatim with indentation" begin
    s = """    @code julia
    println("hey you")
        @end
    """
    ast = parse(AST.NorgDocument, s)
    verb = first(children(ast))
    @test nodevalue(verb).parameters == ["julia"]
end

@testset "Complex verbatim tag" begin
    s = """@verbatim.subtag beep bop i\\ am\\ parameter
    bla
    @end
    outside verbatim
    """
    ast = parse(AST.NorgDocument, s)
    verb, p = children(ast)
    @test nodevalue(verb).tag == "verbatim"
    @test nodevalue(verb).subtag == "subtag"
    @test nodevalue(verb).parameters == ["beep", "bop", "i am parameter"]
    verb_body = first(children(verb))
    @test nodevalue(verb_body).value == "bla\n"
end
