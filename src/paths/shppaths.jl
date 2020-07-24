module SHPPaths

import ..Paths: Path, PathSegment, bulge, dx, dy
import Base: parse, show

export SHPPath, SHPPathSegment,
    DirE, DirENE, DirNE, DirNNE, DirN, DirNNW, DirNW, DirWNW,
    DirW, DirWSW, DirSW, DirSSW, DirS, DirSSE, DirSE, DirESE,
    Vec,
    EndOfShape, PenDown, PenUp,
    ScaleDiv, ScaleMul,
    PushLoc, PopLoc,
    Subshape,
    Disp, Disps,
    OctArc, FracArc, BulgeArc, BulgeArcs,
    IfVertical

abstract type SHPPathSegment{cmd} <: PathSegment end

struct SHPPath{T <: Union{UInt8, UInt16}} <: Path
    segments::Vector{SHPPathSegment}
end

SHPPath(segments::AbstractVector{SHPPathSegment}) = SHPPath{UInt16}(segments)

struct Dir{dir} end
DirE   = Dir{0x0}
DirENE = Dir{0x1}
DirNE  = Dir{0x2}
DirNNE = Dir{0x3}
DirN   = Dir{0x4}
DirNNW = Dir{0x5}
DirNW  = Dir{0x6}
DirWNW = Dir{0x7}
DirW   = Dir{0x8}
DirWSW = Dir{0x9}
DirSW  = Dir{0xA}
DirSSW = Dir{0xB}
DirS   = Dir{0xC}
DirSSE = Dir{0xD}
DirSE  = Dir{0xE}
DirESE = Dir{0xF}

# Some unofficial documents assign the directions evenly in 22.5° increments,
# but the slope of `Dir{0x1}` is 1/2 (i.e. ~26.565°).
const DIR_DY = Tuple(Int8[0, 1, 2, 2, 2,  2,  2,  1,  0, -1, -2, -2, -2, -2, -2, -1])
const DIR_DX = Tuple(Int8[2, 2, 2, 1, 0, -1, -2, -2, -2, -2, -2, -1,  0,  1,  2,  2])

const DIR_SYMBOLS = (:DirE, :DirENE, :DirNE, :DirNNE, :DirN, :DirNNW, :DirNW, :DirWNW,
                     :DirW, :DirWSW, :DirSW, :DirSSW, :DirS, :DirSSE, :DirSE, :DirESE)


struct Vec{vec} <: SHPPathSegment{vec} end

function Vec(unitlength::Integer, ::Type{Dir{dir}}) where {dir}
    1 <= unitlength <= 15 || throw(ArgumentError("`unitlength` must be in [1, 15]"))
    Vec{(unitlength % UInt8) << 0x4 + dir}()
end
dx(::Vec{vec}) where {vec} = @inbounds Int8(vec >> 0x4) * DIR_DX[vec & 0xf + 1] * 0.5f0
dy(::Vec{vec}) where {vec} = @inbounds Int8(vec >> 0x4) * DIR_DY[vec & 0xf + 1] * 0.5f0

struct EndOfShape <: SHPPathSegment{0x00} end

struct PenDown <: SHPPathSegment{0x01} end

struct PenUp <: SHPPathSegment{0x02} end

struct ScaleDiv <: SHPPathSegment{0x03}
    scale::UInt8
end

struct ScaleMul <: SHPPathSegment{0x04}
    scale::UInt8
end

struct PushLoc <: SHPPathSegment{0x05} end

struct PopLoc <: SHPPathSegment{0x06} end

struct Subshape{T <: Union{UInt8, UInt16}} <: SHPPathSegment{0x7}
    subshape::T
end

struct Disp <: SHPPathSegment{0x08}
    x::Int8
    y::Int8
end
Disp(dx::Real, dy::Real) = Disp(round(Int8, dx), round(Int8, dy))

dx(disp::Disp) = Float32(disp.x)
dy(disp::Disp) = Float32(disp.y)
distance(disp::Disp) = sqrt(dx(disp)^2 + dy(disp)^2)

struct Disps{N} <: SHPPathSegment{0x09}
    disps::NTuple{N, Disp}
end

struct OctArc <: SHPPathSegment{0x0A}
    radius::UInt8
    sc::Int8
end

struct FracArc <: SHPPathSegment{0x0B}
    start_offset::UInt8
    end_offset::UInt8
    radius::UInt16
    octants::Int8
end

struct BulgeArc <: SHPPathSegment{0x0C}
    disp::Disp
    bulge::Int8
end
BulgeArc(dx::Real, dy::Real, bulge::Real) = BulgeArc(Disp(dx, dy), round(Int8, bulge * 127.0))
bulge(b::BulgeArc) = b.bulge / 127.0f0
sagitta(b::BulgeArc) = Float32(b.bulge * distance(b.disp) / 254)
radius(b::BulgeArc) = Float32(b.bulge * distance(b.disp) / 254)

struct BulgeArcs{N} <: SHPPathSegment{0x0D}
    arcs::NTuple{N, BulgeArc}
end

struct IfVertical <: SHPPathSegment{0x0E} end

const SEGMENT_TYPES = [
    PenDown,
    PenUp,
    ScaleDiv,
    ScaleMul,
    PushLoc,
    PopLoc,
    Subshape,
    Disp,
    Disps,
    OctArc,
    FracArc,
    BulgeArc,
    BulgeArcs,
    IfVertical
]

mutable struct SHPContext{T <: Real}
    stack::Vector{Tuple{T, T}}
    sx::T
    sy::T
    cx::T
    cy::T
    dx::T
    dy::T
    scale::Rational{UInt}
    pendown::Bool
    skip::Bool

    SHPContext{T}() where {T} = new{T}([], 0, 0, 0, 0, 0, 0, 1, true, false)
end

function move_cursor(ctx::SHPContext)
    ctx.cx += ctx.dx
    ctx.cy += ctx.dy
end

function mark_as_start(ctx::SHPContext)
    ctx.sx = ctx.cx
    ctx.sy = ctx.cy
end

function clear_delta(ctx::SHPContext)
    ctx.dx, ctx.dy = zero(ctx.dx), zero(ctx.dy)
end


function parse(::Type{SHPPath{T}}, spec::AbstractString) where {T}
    values = split(spec, r"\s*[()]?\s*,\s*[()]?\s*"s)
    numbers = filter!(s -> !isempty(s), values)
    specbytes = parse_shp_number.(numbers) .% T
    segments = SHPPathSegment[]
    i = 1
    while i <= length(specbytes)
        cmd = specbytes[i] % UInt8
        i += 1
        if cmd === 0x00
            push!(segments, EndOfShape())
        elseif cmd in (0x01, 0x02, 0x05, 0x06, 0x0E)
            push!(segments, SEGMENT_TYPES[cmd]())
        elseif cmd === 0x03 || cmd === 0x04
            scale = specbytes[i] % Int8
            i += 1
            push!(segments, SEGMENT_TYPES[cmd](scale))
        elseif cmd === 0x07
            sub = specbytes[i] % UInt16
            i += 1
            push!(segments, Subshape{T}(sub))
        elseif cmd === 0x08
            x = specbytes[i + 0] % Int8
            y = specbytes[i + 1] % Int8
            i += 2
            push!(segments, Disp(x, y))
        elseif cmd === 0x09
            disps = Disp[]
            while true
                x = specbytes[i + 0] % Int8
                y = specbytes[i + 1] % Int8
                i += 2
                if x === y === Int8(0)
                    push!(segments, Disps(Tuple(disps)))
                    break
                end
                push!(disps, Disp(x, y))
            end
        elseif cmd === 0x0A
            radius = specbytes[i + 0] % UInt8
            sc = specbytes[i + 1] % Int8
            i += 2
            push!(segments, OctArc(radius, sc))
        elseif cmd === 0x0C
            start_offset = specbytes[i + 0] % UInt8
            end_offset = specbytes[i + 1] % Int8
            high_radius = specbytes[i + 2] % UInt8
            radius = specbytes[i + 3] % UInt8
            sc = specbytes[i + 4] % Int8
            i += 5
            farc = FracArc(start_offset, end_offset, high_radius << 0x8 + radius, sc)
            push!(segments, farc)
        elseif cmd === 0x0C
            x = specbytes[i + 0] % Int8
            y = specbytes[i + 1] % Int8
            bulge = specbytes[i + 2] % Int8
            i += 3
            push!(segments, BulgeArc(Disp(x, y), bulge))
        elseif cmd === 0x0D
            arcs = BulgeArc[]
            while true
                x = specbytes[i + 0] % Int8
                y = specbytes[i + 1] % Int8
                i += 2
                if x === y === Int8(0)
                    push!(segments, BulgeArcs(Tuple(arcs)))
                    break
                end
                bulge = specbytes[i + 2] % Int8
                i += 1
                push!(arcs, BulgeArc(Disp(x, y), bulge))
            end
        else
            push!(segments, Vec{cmd}())
        end
    end
    SHPPath{T}(segments)
end

function parse_shp_number(s::AbstractString)
    b = s[1] == '-' ? 2 : 1
    parse(Int, s, base=(s[b] == '0' ? 16 : 10))
end

function Base.show(io::IO, ::Vec{vec}) where {vec}
    print(io, "Vec(", Int(vec >> 0x4), ", ", DIR_SYMBOLS[vec & 0xf + 1], ')')
end

end # module
