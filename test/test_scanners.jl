@testset "Line ending tokens" begin
    @test Norg.Scanners.scan(Norg.Scanners.LineEnding(), "\r\nfoo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Scanners.LineEnding(), "foo") |>
    !(Norg.Scanners.success)
    @test Norg.is_line_ending(Norg.Scanners.scan("\r\nfoo"))
end

@testset "Whitespace tokens" begin
    @test Norg.Scanners.scan(Norg.Scanners.Whitespace(), " foo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Scanners.Whitespace(), "foo") |>
    !Norg.Scanners.success
    @test Norg.is_whitespace(Norg.Scanners.scan("   foo"))
end

@testset "Generic punctuation token" begin
    @test Norg.Scanners.scan(Norg.Scanners.Punctuation(),
                             string(rand(Norg.Scanners.NORG_PUNCTUATION)) *
                             "foo") |>
    Norg.Scanners.success
    @test Norg.Scanners.scan(Norg.Scanners.Punctuation(), "foo") |> !Norg.Scanners.success
    @test Norg.is_punctuation(Norg.Scanners.scan(string(rand(Norg.Scanners.NORG_PUNCTUATION)) * "foo"))
end

@testset "Single punctuation kind $kind" for kind in Norg.Kinds.all_single_punctuation_tokens()
    @test Norg.Scanners.scan(kind, "$(kind)foo") |> Norg.Scanners.success
    @test Norg.kind(Norg.Scanners.scan("$(kind)foo")) == kind
    @test Norg.Scanners.scan(kind, "foo") |> !Norg.Scanners.success
end

@testset "Word token" begin
    @test Norg.Scanners.scan(Norg.Scanners.Word(), "foo") |> Norg.Scanners.success
    @test Norg.Scanners.scan("foo") |> Norg.is_word
    @test Norg.Scanners.scan(Norg.Scanners.Word(), "}foo") |> !Norg.Scanners.success
end
