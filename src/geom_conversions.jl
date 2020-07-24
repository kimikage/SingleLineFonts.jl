
function octarc_to_arc(::Type{SVGPaths.ArcRel{T}},
    a::SHPPaths.OctArc, scale::Rational=1 // 1) where {T}
    r = a.radius * scale
    asc = abs(a.sc)
    s = (asc >> 0x4) * 0.25
    c = (asc & 0x7) * 0.25
    c == 0.0 && throw(ArgumentError("SVG's arc cannot represent a full circle."))
    ac = signbit(a.sc) ? s - c : s + c
    x0, y0 = -cospi(s), sinpi(s) # center of circle
    dx0, dy0 = cospi(ac), -sinpi(ac)
    dx = (x0 + dx0) * r
    dy = (y0 + dy0) * r
    SVGPaths.ArcRel{T}(dx, dy, r, r, 0, c > 1.0, a.sc < 0)
end

function normalized_polyline(c::SVGPaths.CurveToCubicRel{T}, n::Int=16) where {T}
    function normalize(x, y)
        scale = sqrt(c.x^2 + c.y^2)
        c0, s0 = c.x / scale, c.y / scale
        sx, sy = x / scale, y / scale
        # Note that the SVG y-axis is downward, but here we change the y-axis to upward.
        rx = sx * c0 + sy * s0
        ry = sx * s0 - sy * c0
        (rx - T(0.5), ry)
    end
    function lerp(xa, ya, xb, yb, t)
        x = xa * (1 - t) + xb * t
        y = ya * (1 - t) + yb * t
        (x, y)
    end

    x0, y0 = T(-0.5), T(0)
    x1, y1 = normalize(c.x1, c.y1)
    x2, y2 = normalize(c.x2, c.y2)
    x3, y3 = T(0.5), T(0)

    polyline = Vector{Tuple{T,T}}(undef, n + 1)

    @inbounds for i = 0:n
        t = T(i) / n
        x01, y01 = lerp(x0, y1, x1, y1, t)
        x12, y12 = lerp(x1, y1, x2, y2, t)
        x23, y23 = lerp(x2, y2, x3, y3, t)

        xl, yl = lerp(x01, y01, x12, y12, t)
        xr, yr = lerp(x12, y12, x23, y23, t)

        polyline[i+1] = lerp(xl, yl, xr, yr, t)
    end
    return polyline
end

function normalized_polyline(c::SHPPaths.BulgeArc, xs::AbstractVector)
    h = abs(c.bulge) / 254.0f0 # normalized
    r = (0.25f0 + h^2) / (h + h)

    n = length(xs)
    polyline = Vector{Tuple{Float32,Float32}}(undef, n)

    @inbounds for i in 1:n
        x = Float32(xs[i])
        y = sqrt(r^2 - x^2) - (r - h)
        polyline[i] = (x, copysign(y, c.bulge))
    end
    return polyline
end


function cubic_to_bulge(::Type{SHPPaths.BulgeArc}, c::SVGPaths.CurveToCubicRel{T}) where {T}
    pc = normalized_polyline(c, 16)
    ya, yb = pc[2][2], pc[16][2]
    if ya * yb < 0
        throw(ArgumentError("S-curves are not supported. Add a midpoint manually."))
    end

    b = SHPPaths.BulgeArc(0, 0, 0) # dummy
    evmin = Inf
    @inbounds for i = 1:127
        bi = SHPPaths.BulgeArc(c.x, -c.y, copysign(i, ya))
        pb = normalized_polyline(bi, map(t -> t[1], pc))
        ev = sum(t -> (t[1][2] - t[2][2])^2, zip(pc, pb))
        ev > evmin && break
        b = bi
        evmin = ev
    end
    return b
end

function bulge_to_cubic(::Type{SVGPaths.CurveToCubicRel{T}},
    c::SHPPaths.BulgeArc, scale::Rational=1 // 1) where {T}
    h = abs(c.bulge) / T(254) # normalized
    r = (T(0.25) + h^2) / (h + h)
    y1a = T(4) / 3 * h
    x1 = y1a * (r - h) * 2 - T(0.5)
    y1 = copysign(y1a, c.bulge)

    function materialize(x, y)
        dscale = T(distance(c.disp)) * scale
        c0, s0 = c.disp.dx / scale, -c.disp.dy / scale
        tx = x + T(0.5)
        # note that the y-axis direction is different between SVG and SHP
        rx = tx * c0 + y * s0
        ry = tx * s0 - y * c0
        (rx * dscale, ry * dscale)
    end
    p1 = materialize(x1, y1)
    p2 = materialize(-x1, y1)
    dx = c.disp.dx * scale
    dy = c.disp.dy * scale
    return SVGPaths.CurveToCubicRel{T}(dx, dy, p1[1], p1[2], p2[1], p2[2])
end

function push_disps!(segments::Vector{SHPPaths.SHPPathSegment}, x, y, pendown::Bool=true)
    ix, iy = Int(round(x * 8) * 0.125), Int(round(x * 8) * 0.125)
    ix === 0 && iy === 0 && return
    if ix == 0
        if -15 <= iy <= 15
            #push!(segments, iy < 0 ? SHPaths.VecS{-iy}() : SHPPaths.VecN{y}())
            return
        elseif -30 <= iy <= 30
            hy = abs(iy) ÷ 2
            #push!(segments, iy < 0 ? SHPaths.VecS{hy}() : SHPPaths.VecN{hy}())
            #push!(segments, iy < 0 ? SHPaths.VecS{-iy - hy}() : SHPPaths.VecN{iy - hy}())
            return
        end
    elseif iy == 0
        if -15 <= ix <= 15
            #push!(segments, x < 0 ? SHPaths.VecW{-ix}() : SHPPaths.VecE{ix}())
            return
        elseif -30 <= ix <= 30
            hx = abs(ix) ÷ 2
            #push!(segments, y < 0 ? SHPaths.VecW{hx}() : SHPPaths.VecE{hx}())
            #push!(segments, y < 0 ? SHPaths.VecW{-ix - hx}() : SHPPaths.VecE{ix - hx}())
            return
        end
    elseif abs(ix) == abs(iy)
        dir = ifelse(ix < 0, iy < 0 ? SHPPaths.DirSW : SHPPaths.DirNW,
            iy < 0 ? SHPPaths.DirSE : SHPPaths.DirNE)
        if -15 <= ix <= 15
            push!(segments, SHPPaths.Vec(abs(ix), dir))
            return
        elseif -30 <= ix <= 30
            hx = abs(ix) ÷ 2
            push!(segments, SHPPaths.Vec(hx, dir))
            push!(segments, SHPPaths.Vec(abs(ix) - hx, dir))
            return
        end
    elseif abs(ix) * 2 == abs(iy)
        dir = ifelse(ix < 0, iy < 0 ? SHPPaths.DirSSW : SHPPaths.DirNNW,
            iy < 0 ? SHPPaths.DirSSE : SHPPaths.DirNNE)
        if -15 <= iy <= 15
            push!(segments, SHPPaths.Vec(abs(iy), dir))
            return
        elseif -30 <= iy <= 30
            hy = abs(iy) ÷ 2
            push!(segments, SHPPaths.Vec(hy, dir))
            push!(segments, SHPPaths.Vec(abs(iy) - hy, dir))
            return
        end
    end
    if (-128 <= ix <= 127) && (-128 <= iy <= 127)
        push!(segments, SHPaths.Vec(15, SHPPaths.DirS))
    else
        throw(ArgumentError("too large vector: ($x, $y)"))
    end
end

function shpglyph_to_svgsegments(ctx::SHPPaths.SHPContext{T},
    svgsegments::Vector{SVGPaths.SVGPathSegment{:rel,T}},
    g::SHPGlyph) where {T}
    shape = g.font.shapes[g.codeunit]
    path = shape.shape
    shpsegments = path.segments
    stacklevel = length(ctx.stack)
    initial_scale = ctx.scale
    for i in 1:length(shpsegments)-1
        if ctx.skip
            ctx.skip = false
            continue
        end
        s = shpsegments[i]
        sn = shpsegments[i+1]
        if s isa Union{SHPPaths.Vec,SHPPaths.Disp,SHPPaths.Disps}
            disps = s isa SHPPaths.Disps ? s.disps : (s,)
            for (di, d) in enumerate(disps)
                ctx.dx += Paths.dx(d) * ctx.scale
                ctx.dy += Paths.dy(d) * ctx.scale
                ctx.pendown || continue
                SHPPaths.move_cursor(ctx)
                if sn isa SHPPaths.PenUp && di == length(disps) &&
                   ctx.cx ≈ ctx.sx && ctx.cy ≈ ctx.sy
                    push!(svgsegments, SVGPaths.ClosePathRel{T}())
                else
                    push!(svgsegments, SVGPaths.LineToRel{T}(ctx.dx, -ctx.dy))
                end
                SHPPaths.clear_delta(ctx)
            end
        elseif s isa SHPPaths.EndOfShape
            break
        elseif s isa SHPPaths.PenUp
            ctx.pendown = false
        elseif s isa SHPPaths.PenDown
            ctx.pendown = true
            push!(svgsegments, SVGPaths.MoveToRel{T}(ctx.dx, -ctx.dy))
            SHPPaths.move_cursor(ctx)
            SHPPaths.mark_as_start(ctx)
            SHPPaths.clear_delta(ctx)
        elseif s isa SHPPaths.ScaleDiv
            ctx.scale /= s.scale
        elseif s isa SHPPaths.ScaleMul
            ctx.scale *= s.scale
        elseif s isa SHPPaths.PushLoc
            length(ctx.stack) < 4 || throw(BoundsError(ctx.stack, 5))
            push!(ctx.stack, (ctx.cx + ctx.dx, ctx.cy + ctx.dy))
        elseif s isa SHPPaths.PopLoc
            cx2, cy2 = pop!(ctx.stack)
            ctx.dx = cx2 - ctx.cx
            ctx.dy = cy2 - ctx.cy
            ctx.pendown = false # this is not well documented
        elseif s isa SHPPaths.Subshape
            sub = glyph(g.font, s.subshape, vertical=g.vertical)
            shpglyph_to_svgsegments(ctx, svgsegments, sub)
        elseif s isa SHPPaths.OctArc
            if s.sc & 0xf == 0x0
                ctx.pendown || continue
                oa1 = SHPPaths.OctArc(s.radius, copysign(abs(s.sc) + 0x4, s.sc))
                oa2 = SHPPaths.OctArc(s.radius, copysign((abs(s.sc) + 0x44) & 0x77, s.sc))
                push!(svgsegments, octarc_to_arc(SVGPaths.ArcRel{T}, oa1, ctx.scale))
                push!(svgsegments, octarc_to_arc(SVGPaths.ArcRel{T}, oa2, ctx.scale))
                SHPPaths.clear_delta(ctx)
                continue
            end
            arc = octarc_to_arc(SVGPaths.ArcRel{T}, s, ctx.scale)
            ctx.dx += arc.x
            ctx.dy += -arc.y
            if ctx.pendown
                push!(svgsegments, arc)
                SHPPaths.move_cursor(ctx)
                SHPPaths.clear_delta(ctx)
            end
        elseif s isa SHPPaths.IfVertical
            ctx.skip = !g.vertical
        end
    end
    length(ctx.stack) == stacklevel || error("missing pop")
    ctx.scale === initial_scale || error("scale restoration error")
end
