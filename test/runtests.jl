using Norg
using Test
using Compat
using AbstractTrees


@testset "Norg.jl" begin
    @testset "tokens.jl" begin
        include("test_tokens.jl") 
    end
    @testset "scanners.jl" begin
        include("test_scanners.jl")
    end
    @testset "Tokenize.jl" begin
        include("test_tokenize.jl")
    end
    @testset "parser.jl" begin
        include("ast_tests/test_markup.jl")
    end
end
