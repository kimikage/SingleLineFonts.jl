using Test, SingleLineFonts

@testset "w/o FileIO" begin
    @test length(methods(SingleLineFonts.load)) == 0
end

using FileIO

module ESRI
    import FileIO: @format_str, File, magic

    function load(f::File{format"Shapefile"})
        return :esri
    end
end

add_format(format"Shapefile", UInt8[0x00, 0x00, 0x27, 0x0a], [".shp", ".shx"], [ESRI])

juliadots_shp = joinpath(@__DIR__, "..", "fonts", "juliadots.shp")
enri_shp = joinpath(@__DIR__, "..", "fonts", "enri.shp")
enri_shx = joinpath(@__DIR__, "..", "fonts", "enri.shx")

@testset "load SHP file" begin
    @test load(juliadots_shp) == :esri
    @test load(enri_shp) == :esri

    SingleLineFonts.add_format_shp()

    @test load(juliadots_shp) isa SHPFont
    @test load(enri_shp) == :esri
end

@testset "load SHX file" begin
    @test load(enri_shx) == :esri

    # TODO: implement and test add_format_shx()
end
