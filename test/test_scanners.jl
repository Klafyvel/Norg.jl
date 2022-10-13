@testset "Line ending tokens" begin
    @test Norg.Scanners.scan(Norg.Tokens.LineEnding(), "\r\nfoo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Tokens.LineEnding(), "foo") |>
    !(Norg.Scanners.success)
    @test Norg.Scanners.scan("\r\nfoo") isa
          Norg.Tokens.Token{Norg.Tokens.LineEnding}
end

@testset "Whitespace tokens" begin
    @test Norg.Scanners.scan(Norg.Tokens.Whitespace(), " foo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Tokens.Whitespace(), "foo") |>
    !Norg.Scanners.success
end

@testset "Generic punctuation token" begin
    @test Norg.Scanners.scan(Norg.Tokens.Punctuation(),
                             string(rand(Norg.Scanners.NORG_PUNCTUATION)) *
                             "foo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Tokens.Punctuation(), "foo") |> !Norg.Scanners.success
end

single_punctuation_tokens = [
    ('*', Norg.Tokens.Star),
    ('/', Norg.Tokens.Slash),
    ('_', Norg.Tokens.Underscore),
    ('-', Norg.Tokens.Minus),
    ('!', Norg.Tokens.ExclamationMark),
    ('^', Norg.Tokens.Circumflex),
    (',', Norg.Tokens.Comma),
    ('`', Norg.Tokens.BackApostrophe),
    ('\\', Norg.Tokens.BackSlash),
    ('{', Norg.Tokens.LeftBrace),
    ('}', Norg.Tokens.RightBrace),
    ('~', Norg.Tokens.Tilde),
    ('>', Norg.Tokens.GreaterThanSign),
    ('@', Norg.Tokens.CommercialAtSign),
    ('=', Norg.Tokens.EqualSign),
]
@testset "Single punctuation token $c" for (c, token) in single_punctuation_tokens
    @test Norg.Scanners.scan(token(), "$(c)foo") |> Norg.Scanners.success
    @test Norg.Scanners.scan("$(c)foo") isa Norg.Token{token}
    @test Norg.Scanners.scan(token(), "foo") |> !Norg.Scanners.success
end

@testset "Word token" begin
    @test Norg.Scanners.scan(Norg.Tokens.Word(), "foo") |> Norg.Scanners.success
    @test Norg.Scanners.scan("foo") isa Norg.Token{Norg.Tokens.Word}
    @test Norg.Scanners.scan(Norg.Tokens.Word(), "}foo") |> !Norg.Scanners.success
end
