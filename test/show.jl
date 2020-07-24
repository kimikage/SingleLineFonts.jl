using Test, SingleLineFonts

juliadots_shp = joinpath(@__DIR__, "fonts", "juliadots.shp")

@testset "show svg: SHPGlyph" begin

    shp = SingleLineFonts.read_shp(juliadots_shp)

    largecircle = SingleLineFonts.glyph(shp, 0x25EF)

    io = IOBuffer()
    show(io, "image/svg+xml", largecircle)
    svg = String(take!(io))

    @test occursin("<path ", svg)
end
