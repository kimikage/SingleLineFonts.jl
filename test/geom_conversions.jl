using Test, SingleLineFonts

using SingleLineFonts.Paths.SVGPaths
using SingleLineFonts.Paths.SHPPaths

@testset "octarc_to_arc" begin
    octarc_01 = OctArc(2, 0x01)
    svgarc_01 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_01)
    @test svgarc_01.x ≈ sqrt(2.0) - 2.0
    @test svgarc_01.y ≈ -sqrt(2.0)
    @test svgarc_01.r1 === svgarc_01.r2 === 2.0
    @test !svgarc_01.large_arc
    @test !svgarc_01.sweep

    octarc_03 = OctArc(2, 0x03)
    svgarc_03 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_03)
    @test svgarc_03.x ≈ -sqrt(2.0) - 2.0
    @test svgarc_03.y ≈ -sqrt(2.0)
    @test svgarc_03.r1 === svgarc_03.r2 === 2.0
    @test !svgarc_03.large_arc
    @test !svgarc_03.sweep

    octarc_04 = OctArc(2, 0x04)
    svgarc_04 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_04)
    @test svgarc_04.x ≈ -4.0
    @test svgarc_04.y ≈ 0.0 atol = eps(2.0)
    @test svgarc_04.r1 === svgarc_04.r2 === 2.0
    @test !svgarc_04.large_arc
    @test !svgarc_04.sweep

    octarc_07 = OctArc(2, 0x07)
    svgarc_07 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_07)
    @test svgarc_07.x ≈ sqrt(2.0) - 2.0
    @test svgarc_07.y ≈ sqrt(2.0)
    @test svgarc_07.r1 === svgarc_07.r2 === 2.0
    @test svgarc_07.large_arc
    @test !svgarc_07.sweep

    octarc_ff = OctArc(2, -Int8(0x01))
    svgarc_ff = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_ff)
    @test svgarc_ff.x ≈ sqrt(2.0) - 2.0
    @test svgarc_ff.y ≈ sqrt(2.0)
    @test svgarc_ff.r1 === svgarc_ff.r2 === 2.0
    @test !svgarc_ff.large_arc
    @test svgarc_ff.sweep

    octarc_34 = OctArc(2, 0x34)
    svgarc_34 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_34)
    @test svgarc_34.x ≈ sqrt(8.0)
    @test svgarc_34.y ≈ sqrt(8.0)
    @test svgarc_34.r1 === svgarc_34.r2 === 2.0
    @test !svgarc_34.large_arc
    @test !svgarc_34.sweep

    octarc_c8 = OctArc(2, -Int8(0x56))
    svgarc_c8 = SingleLineFonts.octarc_to_arc(ArcRel{Float64}, octarc_c8)
    @test svgarc_c8.x ≈ sqrt(8.0)
    @test svgarc_c8.y ≈ 0.0 atol = eps(2.0)
    @test svgarc_c8.r1 === svgarc_c8.r2 === 2.0
    @test svgarc_c8.large_arc
    @test svgarc_c8.sweep

    svgarc_scaled = SingleLineFonts.octarc_to_arc(ArcRel{Float32}, OctArc(5, 0x77), 3 // 5)
    @test svgarc_scaled == SingleLineFonts.octarc_to_arc(ArcRel{Float32}, OctArc(3, 0x77))

    @test_throws ArgumentError SingleLineFonts.octarc_to_arc(ArcRel{Float64}, OctArc(2, 0x70))
end
