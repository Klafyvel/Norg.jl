@test Norg.Scanners.scan('-', Norg.Tokens.Minus(), "-foo") isa
      Norg.Tokens.Token{Norg.Tokens.Minus}
@compat @test Norg.Scanners.scan('-', Norg.Tokens.Minus(), "+foo") |> isnothing
@test Norg.Scanners.scan("\r\n", Norg.Tokens.LineEnding(), "\r\nfoo") isa
      Norg.Tokens.Token{Norg.Tokens.LineEnding}
@compat @test Norg.Scanners.scan("\r\n", Norg.Tokens.LineEnding(), "foo") |>
              isnothing
@test Norg.Scanners.scan(["\r\n", "\n"], Norg.Tokens.LineEnding(),
                         "\r\nfoo") isa
      Norg.Tokens.Token{Norg.Tokens.LineEnding}
@compat @test Norg.Scanners.scan(["\r\n", "\n"], Norg.Tokens.LineEnding(),
                                 "foo") |>
              isnothing
@test Norg.Scanners.scan(Norg.Tokens.LineEnding(), "\r\nfoo") isa
      Norg.Tokens.Token{Norg.Tokens.LineEnding}
@test Norg.Scanners.scan("\r\nfoo") isa
      Norg.Tokens.Token{Norg.Tokens.LineEnding}
@compat @test Norg.Scanners.scan(Norg.Tokens.LineEnding(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Whitespace(), " foo") isa
      Norg.Tokens.Token{Norg.Tokens.Whitespace}
@test Norg.Scanners.scan(Norg.Tokens.Whitespace(),
                         String([' ', Char(0x2006)]) * "foo") isa
      Norg.Tokens.Token{Norg.Tokens.Whitespace}
@test Norg.Scanners.scan(String([' ', Char(0x2006)]) * "foo") isa
      Norg.Tokens.Token{Norg.Tokens.Whitespace}
@compat @test Norg.Scanners.scan(Norg.Tokens.Whitespace(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Punctuation(),
                         string(rand(Norg.Scanners.NORG_PUNCTUATION)) * "foo") isa
      Norg.Tokens.Token{Norg.Tokens.Punctuation}
@test Norg.Scanners.scan(string(rand(Norg.Scanners.NORG_PUNCTUATION)) * "foo") isa
      Norg.Tokens.Token{Norg.Tokens.Punctuation}
@compat @test Norg.Scanners.scan(Norg.Tokens.Punctuation(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Star(), "*foo") isa
      Norg.Token{Norg.Tokens.Star}
@test Norg.Scanners.scan("*foo") isa Norg.Token{Norg.Tokens.Star}
@test Norg.Scanners.scan(Norg.Tokens.Star(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Slash(), "/foo") isa
      Norg.Token{Norg.Tokens.Slash}
@test Norg.Scanners.scan("/foo") isa Norg.Token{Norg.Tokens.Slash}
@test Norg.Scanners.scan(Norg.Tokens.Slash(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Underscore(), "_foo") isa
      Norg.Token{Norg.Tokens.Underscore}
@test Norg.Scanners.scan("_foo") isa Norg.Token{Norg.Tokens.Underscore}
@test Norg.Scanners.scan(Norg.Tokens.Underscore(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Minus(), "-foo") isa
      Norg.Token{Norg.Tokens.Minus}
@test Norg.Scanners.scan("-foo") isa Norg.Token{Norg.Tokens.Minus}
@test Norg.Scanners.scan(Norg.Tokens.Minus(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.ExclamationMark(), "!foo") isa
      Norg.Token{Norg.Tokens.ExclamationMark}
@test Norg.Scanners.scan("!foo") isa Norg.Token{Norg.Tokens.ExclamationMark}
@test Norg.Scanners.scan(Norg.Tokens.ExclamationMark(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Circumflex(), "^foo") isa
      Norg.Token{Norg.Tokens.Circumflex}
@test Norg.Scanners.scan("^foo") isa Norg.Token{Norg.Tokens.Circumflex}
@test Norg.Scanners.scan(Norg.Tokens.Circumflex(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Comma(), ",foo") isa
      Norg.Token{Norg.Tokens.Comma}
@test Norg.Scanners.scan(",foo") isa Norg.Token{Norg.Tokens.Comma}
@test Norg.Scanners.scan(Norg.Tokens.Comma(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.BackApostrophe(), "`foo") isa
      Norg.Token{Norg.Tokens.BackApostrophe}
@test Norg.Scanners.scan("`foo") isa Norg.Token{Norg.Tokens.BackApostrophe}
@test Norg.Scanners.scan(Norg.Tokens.BackApostrophe(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.BackSlash(), "\\foo") isa
      Norg.Token{Norg.Tokens.BackSlash}
@test Norg.Scanners.scan("\\foo") isa Norg.Token{Norg.Tokens.BackSlash}
@test Norg.Scanners.scan(Norg.Tokens.BackSlash(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.LeftBrace(), "{foo") isa
      Norg.Token{Norg.Tokens.LeftBrace}
@test Norg.Scanners.scan("{foo") isa Norg.Token{Norg.Tokens.LeftBrace}
@test Norg.Scanners.scan(Norg.Tokens.LeftBrace(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.RightBrace(), "}foo") isa
      Norg.Token{Norg.Tokens.RightBrace}
@test Norg.Scanners.scan("}foo") isa Norg.Token{Norg.Tokens.RightBrace}
@test Norg.Scanners.scan(Norg.Tokens.RightBrace(), "foo") |> isnothing
@test Norg.Scanners.scan(Norg.Tokens.Word(), "foo") isa
      Norg.Token{Norg.Tokens.Word}
@test Norg.Scanners.scan("foo") isa Norg.Token{Norg.Tokens.Word}
@test Norg.Scanners.scan(Norg.Tokens.Word(), "}foo") |> isnothing
