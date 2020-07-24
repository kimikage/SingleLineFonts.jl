using Test, SingleLineFonts

@testset "NullFont" begin
    nullfont = SingleLineFonts.NullFont()
    @test nullfont isa SingleLineFont

end