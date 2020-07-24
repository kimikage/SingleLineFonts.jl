using Test, SingleLineFonts

@testset "Path" begin
    include("paths/paths.jl")
end

@testset "NullFont" begin
    include("null.jl")
end

@testset "SHPFont" begin
    include("shp.jl")
end

@testset "conversions" begin
    include("conversions.jl")
end

@testset "geom_conversions" begin
    include("geom_conversions.jl")
end

@testset "show" begin
    include("show.jl")
end

@testset "ext FileIO" begin
    include("ext/fileio.jl")
end