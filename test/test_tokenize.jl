tokens = collect(Norg.Tokenize.tokenize("..  .\nBonjour"))
@test Norg.kind(tokens[1]) == K"."
@test length(tokens[1]) == 1
@test Norg.is_whitespace(tokens[3])
@test length(tokens[3]) == 2
@test Norg.line(tokens[4]) == 1
@test Norg.char(tokens[4]) == 5
@test Norg.is_line_ending(tokens[5])
@test Norg.is_word(tokens[6])
@test length(tokens[6]) == 7
@test Norg.value(tokens[6]) == "Bonjour"
@test Norg.line(tokens[6]) == 2
@test Norg.char(tokens[6]) == 1
