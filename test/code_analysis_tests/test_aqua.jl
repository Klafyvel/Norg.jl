using Aqua

@static if VERSION < v"1.9"
    Aqua.test_all(Norg, ambiguities=false, project_toml_formatting=false)
else
    Aqua.test_all(Norg)
end
