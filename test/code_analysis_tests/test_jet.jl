using JET
@testset "JET.jl -> See https://aviatesk.github.io/JET.jl/stable/jetanalysis/#Errors-kinds-and-how-to-fix-them" begin

payload = open(Norg.NORG_SPEC_PATH, "r") do f
    read(f, String)
end

# Error analysis

# Parse the entire spec
@test_call mode=:sound norg(payload)
ast = norg(payload)
# HTML codegen
@test_call mode=:sound Norg.codegen(HTMLTarget(), ast)
# JSON codegen
@test_call mode=:sound Norg.codegen(JSONTarget(), ast)

# Optimization analysis
# Parsing
@test_opt norg(payload)
# Codegen
@test_opt Norg.codegen(HTMLTarget(), payload)
@test_opt Norg.codegen(JSONTarget(), payload)
end


