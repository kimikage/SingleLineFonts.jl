using Test, SingleLineFonts

juliadots_shp = joinpath(@__DIR__, "fonts", "juliadots.shp")

@testset "read_shp" begin
    shp = SingleLineFonts.read_shp(juliadots_shp)
    @test shp isa SHPFont
    @test shp.header_comment == ";;\r\n;;  Julia dots (SHP)\r\n;;\r\n\r\n\r\n"
end
