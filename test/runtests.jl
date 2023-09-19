using Norg
using Test
using AbstractTrees
using Aqua

import Norg: @K_str, kind, value

@testset "Norg.jl" begin
    @testset "scanners.jl" begin
        include("test_scanners.jl")
    end
    @testset "Tokenize.jl" begin
        include("test_tokenize.jl")
    end
    @testset "parser.jl" begin
        include("ast_tests/test_markup.jl")
        include("ast_tests/test_paragraphs.jl")
        include("ast_tests/test_links.jl")
        include("ast_tests/test_headings.jl")
        include("ast_tests/test_nestable_detached_modifiers.jl")
        include("ast_tests/test_tags.jl")
        include("ast_tests/test_detached_modifier_extension.jl")
        include("ast_tests/test_rangeable_detached_modifiers.jl")
        include("ast_tests/test_detached_modifier_suffix.jl")
        # include("ast_tests/misc_bugs.jl")
    end
    @testset "codegen.jl" begin
        include("codegen_tests/html.jl")
        include("codegen_tests/json.jl")
    end
    @testset "code analysis" begin
        if VERSION ≥ v"1.9"
            include("code_analysis_tests/test_jet.jl")
        end
        include("code_analysis_tests/test_aqua.jl")
    end
end
