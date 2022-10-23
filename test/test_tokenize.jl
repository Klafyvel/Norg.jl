tokens = collect(Norg.Tokenize.tokenize("..  .\nBonjour"))
@test Norg.kind(tokens[1]) == K"StartOfFile"
@test Norg.kind(tokens[2]) == K"."
@test length(tokens[2]) == 1
@test Norg.is_whitespace(tokens[4])
@test length(tokens[4]) == 2
@test Norg.line(tokens[5]) == 1
@test Norg.char(tokens[5]) == 5
@test Norg.is_line_ending(tokens[6])
@test Norg.is_word(tokens[7])
@test length(tokens[7]) == 7
@test Norg.value(tokens[7]) == "Bonjour"
@test Norg.line(tokens[7]) == 2
@test Norg.char(tokens[7]) == 1
@test Norg.kind(tokens[end]) == K"EndOfFile"
