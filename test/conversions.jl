using Test, SingleLineFonts

using SingleLineFonts.Paths.SVGPaths
using SingleLineFonts.Paths.SHPPaths

@testset "SVGPath to SHPPath" begin
    svgpath = SVGPath("M10, 20 h 30 v 40 z")
    shppath = convert(SHPPath, svgpath)

    @test shppath isa SHPPath
end
