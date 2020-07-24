module SVGPaths

import ..Paths: Path, PathSegment

import Base: parse, show

export SVGPath, SVGPathSegment,
    ClosePath, ClosePathAbs, ClosePathRel,
    MoveTo, MoveToAbs, MoveToRel,
    LineTo, LineToAbs, LineToRel,
    CurveToCubic, CurveToCubicAbs, CurveToCubicRel,
    Arc, ArcAbs, ArcRel,
    LineToHorizontal, LineToHorizontalAbs, LineToHorizontalRel,
    LineToVertical, LineToVerticalAbs, LineToVerticalRel,
    CurveToCubicSmooth, CurveToCubicSmoothAbs, CurveToCubicSmoothRel

abstract type SVGPathSegment{ar, T <: Real} <: PathSegment end

SVGPathSegmentT{T <: Real} = SVGPathSegment{ar, T} where ar

struct SVGPath{T} <: Path
    d::String
    segments::Vector{SVGPathSegmentT{T}}
end

SVGPath{T}(d::AbstractString) where {T} = parse(SVGPath{T}, d)
SVGPath(d::AbstractString) = parse(SVGPath, d)

function SVGPath(segments::AbstractVector{<:SVGPathSegmentT{T}}) where T
    SVGPath{T}(pathdata(segments), segments)
end

function Base.show(io::IO, path::SVGPath{T}) where T
    print(io, SVGPath{T}, '(')
    show(io, path.d)
    print(io, ')')
end

function show_pathdata(io, segments::AbstractVector{<:SVGPathSegment})
    for (i, seg) in enumerate(segments)
        i > 1 && print(io, ' ')
        show_pathdata(io, seg)
    end
end

function pathdata(s)
    io = IOBuffer()
    show_pathdata(io, s)
    String(take!(io))
end


struct ClosePath{ar, T <: Real} <: SVGPathSegment{ar, T} end
ClosePathAbs{T} = ClosePath{:abs, T}
ClosePathRel{T} = ClosePath{:rel, T}

show_pathdata(io::IO, seg::ClosePath) = print(io, is_absolute(seg) ? 'Z' : 'z')

struct MoveTo{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
    y::T
end
MoveToAbs{T} = MoveTo{:abs, T}
MoveToRel{T} = MoveTo{:rel, T}

function show_pathdata(io::IO, seg::MoveTo)
    print(io, is_absolute(seg) ? "M " : "m ", simplify(seg.x), ',', simplify(seg.y))
end

struct LineTo{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
    y::T
end
LineToAbs{T} = LineTo{:abs, T}
LineToRel{T} = LineTo{:rel, T}

function show_pathdata(io::IO, seg::LineTo)
    print(io, is_absolute(seg) ? "L " : "l ", simplify(seg.x), ',', simplify(seg.y))
end

struct CurveToCubic{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
    y::T
    x1::T
    y1::T
    x2::T
    y2::T
end
CurveToCubicAbs{T} = CurveToCubic{:abs, T}
CurveToCubicRel{T} = CurveToCubic{:rel, T}

function show_pathdata(io::IO, seg::CurveToCubic)
    print(io, is_absolute(seg) ? "C " : "c ")
    print(io, simplify(seg.x1), ',', simplify(seg.y1), ' ')
    print(io, simplify(seg.x2), ',', simplify(seg.y2), ' ')
    print(io, simplify(seg.x), ',', simplify(seg.y))
end

struct Arc{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
    y::T
    r1::T
    r2::T
    angle::T
    large_arc::Bool
    sweep::Bool
end
ArcAbs{T} = Arc{:abs, T}
ArcRel{T} = Arc{:rel, T}

function show_pathdata(io::IO, seg::Arc)
    print(io, is_absolute(seg) ? "A " : "a ")
    print(io, simplify(seg.r1), ',', simplify(seg.r2), ' ')
    print(io, simplify(seg.angle), ' ')
    print(io, seg.large_arc ? '1' : '0', ',', seg.sweep ? '1' : '0', ' ')
    print(io, simplify(seg.x), ',', simplify(seg.y))
end

struct LineToHorizontal{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
end
LineToHorizontalAbs{T} = LineToHorizontal{:abs, T}
LineToHorizontalRel{T} = LineToHorizontal{:rel, T}

function show_pathdata(io::IO, seg::LineToHorizontal)
    print(io, is_absolute(seg) ? "H " : "h ", simplify(seg.x))
end

struct LineToVertical{ar, T <: Real} <: SVGPathSegment{ar, T}
    y::T
end
LineToVerticalAbs{T} = LineToVertical{:abs, T}
LineToVerticalRel{T} = LineToVertical{:rel, T}

function show_pathdata(io::IO, seg::LineToVertical)
    print(io, is_absolute(seg) ? "V " : "v ", simplify(seg.y))
end

struct CurveToCubicSmooth{ar, T <: Real} <: SVGPathSegment{ar, T}
    x::T
    y::T
    x2::T
    y2::T
end
CurveToCubicSmoothAbs{T} = CurveToCubicSmooth{:abs, T}
CurveToCubicSmoothRel{T} = CurveToCubicSmooth{:rel, T}

function show_pathdata(io::IO, seg::CurveToCubicSmooth)
    print(io, is_absolute(seg) ? "S " : "s ")
    print(io, simplify(seg.x2), ',', simplify(seg.y2), ' ')
    print(io, simplify(seg.x), ',', simplify(seg.y))
end

parse(::Type{SVGPath}, d::AbstractString) = parse(SVGPath{Float64}, d)

function parse(::Type{SVGPath{T}}, d::AbstractString) where {T <: Real}
    original_d = String(d)
    segments = SVGPathSegmentT{T}[]
    while !isempty(d)
        m = match(r"[ \t\n\r]*([MmZzLlHhVvCcSsQqTtAa])[ \t\n\r]*(.*)"s, d)
        m === nothing && throw(ArgumentError("invalid path data: $d"))
        cmd, d = m.captures
        cmdl = lowercase(cmd[1])
        ar = islowercase(cmd[1]) ? :rel : :abs
        while true
            if cmdl == 'm'
                x, d = parse_number(T, d, true)
                y, d = parse_number(T, d)
                push!(segments, MoveTo{ar, T}(x, y))
            elseif cmdl == 'z'
                push!(segments, ClosePath{ar, T}())
            elseif cmdl == 'l'
                x, d = parse_number(T, d, true)
                y, d = parse_number(T, d)
                push!(segments, LineTo{ar, T}(x, y))
            elseif cmdl == 'h'
                x, d = parse_number(T, d)
                push!(segments, LineToHorizontal{ar, T}(x))
            elseif cmdl == 'v'
                y, d = parse_number(T, d)
                push!(segments, LineToVertical{ar, T}(y))
            elseif cmdl == 'c'
                x1, d = parse_number(T, d, true)
                y1, d = parse_number(T, d, true)
                x2, d = parse_number(T, d, true)
                y2, d = parse_number(T, d, true)
                x, d = parse_number(T, d, true)
                y, d = parse_number(T, d)
                push!(segments, CurveToCubic{ar, T}(x, y, x1, y1, x2, y2))
            elseif cmdl == 's'
                x2, d = parse_number(T, d, true)
                y2, d = parse_number(T, d, true)
                x, d = parse_number(T, d, true)
                y, d = parse_number(T, d)
                push!(segments, CurveToCubicSmooth{ar, T}(x, y, x2, y2))
            elseif cmdl == 'a'
                r1, d = parse_number(T, d, true)
                r2, d = parse_number(T, d, true)
                angle, d = parse_number(T, d, true)
                large_arc, d = parse_number(T, d, true)
                sweep, d = parse_number(T, d, true)
                x, d = parse_number(T, d, true)
                y, d = parse_number(T, d)
                push!(segments, Arc{ar, T}(x, y, r1, r2, angle, large_arc, sweep))
            else
                throw(ArgumentError("not yet supported: $cmd"))
            end
            isempty(d) && break
            occursin(r"^[MmZzLlHhVvCcSsQqTtAa]", d) && break
        end
    end
    SVGPath(original_d, segments)
end

function parse_number(T::Type, d, comma::Bool = false)
    m = match(r"([+-]?(?:\d+(?:\.\d*)?|(?:\.\d*))(?:[eE][+-]?\d+)?)[ \t\n\r]*(.*)"s, d)
    m === nothing && throw(ArgumentError("invalid path data: $d"))
    num, d = m.captures
    if comma
        m = match(r",?[ \t\n\r]*(.*)"s, d)
        m === nothing && throw(ArgumentError("invalid path data: $d"))
        d = m.captures[1]
    end
    return  parse(T, num), d
end

is_absolute(::SVGPathSegment{ar}) where {ar} = ar === :abs

function to_relative(path::SVGPath{T}) where T
    cx, cy = zero(T), zero(T)
    sx, sy = zero(T), zero(T)
    segments = SVGPathSegment{:rel, T}[]
    for seg in path.segments
        if seg isa ClosePath
            push!(segments, ClosePathRel{T}())
            cx, cy = sx, sy
        elseif seg isa MoveTo
            x = is_absolute(seg) ? seg.x - cx : seg.x
            y = is_absolute(seg) ? seg.y - cy : seg.y
            push!(segments, MoveToRel{T}(x, y))
            cx, cy = cx + x, cy + y
            sx, sy = cx, cy
        elseif seg isa LineTo
            x = is_absolute(seg) ? seg.x - cx : seg.x
            y = is_absolute(seg) ? seg.y - cy : seg.y
            push!(segments, LineToRel{T}(x, y))
            cx, cy = cx + x, cy + y
        elseif seg isa CurveToCubic
            x = is_absolute(seg) ? seg.x - cx : seg.x
            y = is_absolute(seg) ? seg.y - cy : seg.y
            x1 = is_absolute(seg) ? seg.x1 - cx : seg.x1
            y1 = is_absolute(seg) ? seg.y1 - cy : seg.y1
            x2 = is_absolute(seg) ? seg.x2 - cx : seg.x2
            y2 = is_absolute(seg) ? seg.y2 - cy : seg.y2
            push!(segments, CurveToCubicRel{T}(x, y, x1, y1, x2, y2))
            cx, cy = cx + x, cy + y
        elseif seg isa LineToHorizontal
            x = is_absolute(seg) ? seg.x - cx : seg.x
            push!(segments, LineToHorizontalRel{T}(x))
            cx = cx + x
        elseif seg isa LineToVertical
            y = is_absolute(seg) ? seg.y - cy : seg.y
            push!(segments, LineToVerticalRel{T}(y))
            cy = cy + y
        elseif seg isa CurveToCubicSmooth
            x = is_absolute(seg) ? seg.x - cx : seg.x
            y = is_absolute(seg) ? seg.y - cy : seg.y
            x2 = is_absolute(seg) ? seg.x2 - cx : seg.x2
            y2 = is_absolute(seg) ? seg.y2 - cy : seg.y2
            push!(segments, CurveToCubicSmoothRel{T}(x, y, x2, y2))
            cx, cy = cx + x, cy + y
        else
            throw(ArgumentError("not yet supported: $seg"))
        end
    end
    SVGPath(segments)
end

function to_absolute(path::SVGPath{T}) where T

end

function to_intrinsic(path::SVGPath{T}) where T
    segments = copy(to_relative(path).segments)
    sx1, sy1 = zero(T), zero(T)
    prev = Nothing
    for (i, seg) in enumerate(segments)
        if seg isa LineToHorizontal
            segments[i] = LineToRel{T}(seg.x, zero(T))
        elseif seg isa LineToVertical
            segments[i] = LineToRel{T}(zero(T), seg.y)
        elseif seg isa CurveToCubic
            sx1, sy1 = seg.x - seg.x2, seg.y - seg.y2
        elseif seg isa CurveToCubicSmooth
            if prev <: Union{CurveToCubic, CurveToCubicSmooth}
                x1, y1 = sx1, sy1
            else
                x1, y1 = zero(T), zero(T)
            end
            segments[i] = CurveToCubicRel{T}(seg.x, seg.y, x1, y1, seg.x2, seg.y2)
            sx1, sy1 = seg.x - seg.x2, seg.y - seg.y2
        end
        prev = typeof(seg)
    end
    SVGPath(segments)
end

function simplify(x::Real)
    r = round(x, digits=6)
    string(isinteger(r) ? Int(r) : r)
end

end # module
