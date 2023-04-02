using JET, AbstractTrees, OrderedCollections
@testset "JET.jl -> See https://aviatesk.github.io/JET.jl/stable/jetanalysis/#Errors-kinds-and-how-to-fix-them" begin

payload = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end

# Error analysis

# Parse the entire spec
@test_call ignored_modules=(AbstractTrees, Base) norg(payload)
ast = norg(payload)
# HTML codegen
@test_call ignored_modules=(AbstractTrees, Base) Norg.codegen(HTMLTarget(), ast)
# JSON codegen
@test_call ignored_modules=(AbstractTrees, Base) Norg.codegen(JSONTarget(), ast)

# Optimization analysis
# Parsing
@test_opt ignored_modules=(AbstractTrees, Base) norg(payload)
# Codegen
@test_opt ignored_modules=(AbstractTrees, Base) Norg.codegen(HTMLTarget(), ast)
@test_opt ignored_modules=(AbstractTrees, OrderedCollections, Base) Norg.codegen(JSONTarget(), ast)
end


