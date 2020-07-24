using Test, SingleLineFonts

using SingleLineFonts.Paths.SHPPaths

@testset "parse" begin
    path = parse(SHPPath{UInt16}, """
        2, 14, 8, (-14,21), 8, (6,1), 1,
        9, (-2,3), (-1,4), (0,0),
        024,
        9, (1,4), (2,3), (3,2), (4,1), (0,0),
        020,
        9, (4,-1), (3,-2), (2,-3), (1,-4), (0,0),
        02C,
        9, (-1,-4), (-2,-3), (-3,-2), (-4,-1), (0,0),
        028,
        9, (-4,1), (-3,2), (0,0),
        2, 8, (22,1), 14, 0E9, 0""")
    @test length(path.segments) == 19
    @test path.segments[1] === PenUp()
    @test path.segments[2] === IfVertical()
    @test path.segments[3] === Disp(-14, 21)
    @test path.segments[4] === Disp(6, 1)
    @test path.segments[5] === PenDown()
    @test path.segments[6] === Disps{2}((Disp(-2, 3), Disp(-1, 4)))
    @test path.segments[7] === Vec(2, DirN)
    @test path.segments[8] === Disps{4}((Disp(1, 4), Disp(2, 3), Disp(3, 2), Disp(4, 1)))
    @test path.segments[9] === Vec(2, DirE)
    @test path.segments[10] === Disps{4}((Disp(4, -1), Disp(3, -2), Disp(2, -3), Disp(1, -4)))
    @test path.segments[11] === Vec(2, DirS)
    @test path.segments[12] === Disps{4}((Disp(-1, -4), Disp(-2, -3), Disp(-3, -2), Disp(-4, -1)))
    @test path.segments[13] === Vec(2, DirW)
    @test path.segments[14] === Disps{2}((Disp(-4, 1), Disp(-3, 2)))
    @test path.segments[15] === PenUp()
    @test path.segments[16] === Disp(22, 1)
    @test path.segments[17] === IfVertical()
    @test path.segments[18] === Vec(14, DirWSW)
    @test path.segments[19] === EndOfShape()
end