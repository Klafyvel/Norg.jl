@testset "Line ending tokens" begin
    @test Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.LineEnding(), "\r\nfoo"))
    @test !(Norg.Scanners.success)(Norg.Scanners.scan(Norg.Scanners.LineEnding(), "foo"))
    @test Norg.is_line_ending(Norg.Scanners.scan("\r\nfoo"))
end

@testset "Whitespace tokens" begin
    @test Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.Whitespace(), " foo"))
    @test !Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.Whitespace(), "foo"))
    @test Norg.is_whitespace(Norg.Scanners.scan("   foo"))
end

@testset "Generic punctuation token" begin
    @test Norg.Scanners.success(Norg.Scanners.scan(
        Norg.Scanners.Punctuation(), string(rand(Norg.Scanners.NORG_PUNCTUATION)) * "foo"
    ))
    @test !Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.Punctuation(), "foo"))
    @test Norg.is_punctuation(
        Norg.Scanners.scan(string(rand(Norg.Scanners.NORG_PUNCTUATION)) * "foo")
    )
end

@testset "Single punctuation kind $kind" for kind in
                                             Norg.Kinds.all_single_punctuation_tokens()
    @test Norg.Scanners.success(Norg.Scanners.scan(kind, "$(kind)foo"))
    @test Norg.kind(Norg.Scanners.scan("$(kind)foo")) == kind
    @test !Norg.Scanners.success(Norg.Scanners.scan(kind, "foo"))
end

@testset "Word token" begin
    @test Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.Word(), "foo"))
    @test Norg.is_word(Norg.Scanners.scan("foo"))
    @test !Norg.Scanners.success(Norg.Scanners.scan(Norg.Scanners.Word(), "}foo"))
end
