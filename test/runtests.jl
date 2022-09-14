using Norg
using Test
using Compat

@testset "Norg.jl" begin
    @testset "tokens.jl" begin
        @test Norg.Tokens.Token(Norg.Tokens.LineEnding(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Whitespace(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Punctuation(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Star(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Slash(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Underscore(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Minus(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.Circumflex(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.VerticalBar(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.BackApostrophe(), 1, 1, "") isa Norg.Tokens.Token
        @test Norg.Tokens.Token(Norg.Tokens.BackSlash(), 1, 1, "") isa Norg.Tokens.Token
    end
    @testset "scanners.jl" begin
        @test Norg.Scanners.scan('-', Norg.Tokens.Minus(), "-foo") isa Norg.Tokens.Token{Norg.Tokens.Minus}
        @test Norg.Scanners.scan('-', Norg.Tokens.Minus(), "+foo") |> isnothing
        @test Norg.Scanners.scan("\r\n", Norg.Tokens.LineEnding(), "\r\nfoo") isa Norg.Tokens.Token{Norg.Tokens.LineEnding}
        @test Norg.Scanners.scan("\r\n", Norg.Tokens.LineEnding(), "foo") |> isnothing
        @test Norg.Scanners.scan(["\r\n", "\n"], Norg.Tokens.LineEnding(), "\r\nfoo") isa Norg.Tokens.Token{Norg.Tokens.LineEnding}
        @test Norg.Scanners.scan(["\r\n", "\n"], Norg.Tokens.LineEnding(), "foo") |> isnothing
        @test Norg.Scanners.scan(Norg.Scanners.LineEnding(), "\r\nfoo") isa Norg.Tokens.Token{Norg.Tokens.LineEnding}
        @test Norg.Scanners.scan(Norg.Scanners.LineEnding(), "foo") |> isnothing
        @test Norg.Scanners.scan(Norg.Scanners.Whitespace(), " foo") isa Norg.Tokens.Token{Norg.Tokens.Whitespace}
        @test Norg.Scanners.scan(Norg.Scanners.Whitespace(), String([' ', Char(0x2006)]) * "foo") isa Norg.Tokens.Token{Norg.Tokens.Whitespace}
        @test Norg.Scanners.scan(Norg.Scanners.Whitespace(), "foo") |> isnothing
        # TODO: write test for Norg.Scanners.scan(input; line, charnum)
    end
end
