using Test, SingleLineFonts

using SingleLineFonts.Paths.SVGPaths

@testset "parse" begin
    path = parse(SVGPath, "M 100 100 L 200 200")
    @test path.d == "M 100 100 L 200 200"
    @test length(path.segments) == 2
    @test path.segments[1] === MoveToAbs{Float64}(100, 100)
    @test path.segments[2] === LineToAbs{Float64}(200, 200)

    path = parse(SVGPath, "M100 100L200 200")
    @test path.d == "M100 100L200 200"
    @test length(path.segments) == 2
    @test path.segments[1] === MoveToAbs{Float64}(100, 100)
    @test path.segments[2] === LineToAbs{Float64}(200, 200)

    path = parse(SVGPath, "M 100 200 L 200 100 -100 -200")
    @test path.d == "M 100 200 L 200 100 -100 -200"
    @test length(path.segments) == 3
    @test path.segments[1] === MoveToAbs{Float64}(100, 200)
    @test path.segments[2] === LineToAbs{Float64}(200, 100)
    @test path.segments[3] === LineToAbs{Float64}(-100, -200)

    path = parse(SVGPath, "M100,200 C100,100 250,100 250,200\nS400,300 400,200")
    @test path.d == "M100,200 C100,100 250,100 250,200\nS400,300 400,200"
    @test length(path.segments) == 3
    @test path.segments[1] === MoveToAbs{Float64}(100, 200)
    @test path.segments[2] === CurveToCubicAbs{Float64}(250, 200, 100, 100, 250, 100)
    @test path.segments[3] === CurveToCubicSmoothAbs{Float64}(400, 200, 400, 300)

    path = parse(SVGPath, "M 100-200M 0.6.5")
    @test length(path.segments) == 2
    @test path.segments[1] === MoveToAbs{Float64}(100, -200)
    @test path.segments[2] === MoveToAbs{Float64}(0.6, 0.5)

    path = parse(SVGPath{Float32}, "M300,200 h-150 a150,150 0 1,0 150,-150 z")
    @test length(path.segments) == 4
    @test path.segments[1] === MoveToAbs{Float32}(300, 200)
    @test path.segments[2] === LineToHorizontalRel{Float32}(-150)
    @test path.segments[3] === ArcRel{Float32}(150, -150, 150, 150, 0, 1, 0)
    @test path.segments[4] === ClosePathRel{Float32}()
end

@testset "show" begin
    path = SVGPath{Float32}("M 100-200\tM 0.6.5")
    io = IOBuffer()
    show(io, path)
    @test String(take!(io)) == "SVGPath{Float32}(\"M 100-200\\tM 0.6.5\")"
end

@testset "to_relative" begin
    path = SVGPath("M 100 100 L 200 200 H 300 V 100 Z")
    path_rel = SVGPaths.to_relative(path)
    @test path_rel.d == "m 100,100 l 100,100 h 100 v -100 z"
    @test length(path_rel.segments) == 5
    @test path_rel.segments[1] === MoveToRel{Float64}(100, 100)
    @test path_rel.segments[2] === LineToRel{Float64}(100, 100)
    @test path_rel.segments[3] === LineToHorizontalRel{Float64}(100)
    @test path_rel.segments[4] === LineToVerticalRel{Float64}(-100)
    @test path_rel.segments[5] === ClosePathRel{Float64}()
end

@testset "to_intrinsic" begin
    path = SVGPath("M600,800 C625,700 725,700 750,800 S875,900 900,800")
    path_i = SVGPaths.to_intrinsic(path)
    @test path_i.d == "m 600,800 c 25,-100 125,-100 150,0 c 25,100 125,100 150,0"
    @test length(path_i.segments) == 3
end
