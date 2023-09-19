using Pkg: Pkg
Pkg.add("JuliaFormatter")
using TOML, JuliaFormatter
format(".")
projecttoml = TOML.parsefile("Project.toml")
const _project_key_order = [
    "name",
    "uuid",
    "keywords",
    "license",
    "desc",
    "deps",
    "weakdeps",
    "extensions",
    "compat",
    "extras",
    "targets",
]
function project_key_order(key::String)
    return something(
        findfirst(x -> x == key, _project_key_order), length(_project_key_order) + 1
    )
end

function print_project(io, dict)
    return TOML.print(io, dict; sorted=true, by=key -> (project_key_order(key), key))
end

open("Project.toml", "w") do io
    @info "whoh" io
    write(io, sprint(print_project, projecttoml))
end
