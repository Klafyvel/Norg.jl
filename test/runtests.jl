using Norg
using Test
using Compat
using AbstractTrees

@testset "Norg.jl" begin
    @testset "tokens.jl" begin include("test_tokens.jl") end
    @testset "scanners.jl" begin include("test_scanners.jl") end
    @testset "Tokenize.jl" begin include("test_tokenize.jl") end
    @testset "parser.jl" begin
        include("ast_tests/test_markup.jl")
        include("ast_tests/test_paragraphs.jl")
        include("ast_tests/test_links.jl")
        include("ast_tests/test_headings.jl")
        include("ast_tests/test_nestable_detached_modifiers.jl")
        include("ast_tests/test_tags.jl")
        include("ast_tests/misc_bugs.jl")
    end
    @testset "codegen.jl" begin include("codegen_tests/html.jl") end
end
