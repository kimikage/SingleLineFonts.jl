
function Base.convert(::Type{SHPPath}, path::SVGPath{T}) where {T}
    path_i = SVGPaths.to_intrinsic(path)
    segments = SHPPaths.SHPPathSegment[]
    cx, cy = zero(T), zero(T)
    sx, sy = zero(T), zero(T)
    for seg in path_i.segments
        if seg isa SVGPaths.ClosePathRel
            push!(segments, SHPPaths.PopLoc())
        elseif seg isa SVGPaths.MoveToRel
            push!(segments, SHPPaths.PenUp())
            push_disps!(segments, seg.x, seg.y)
            push!(segments, SHPPaths.PenDown())
            push!(segments, SHPPaths.PushLoc())
        elseif seg isa SVGPaths.LineToRel
            push_disps!(segments, seg.x, seg.y)
        end
    end
    return SHPPaths.SHPPath(segments)
end

function Base.convert(::Type{SVGPaths.SVGPath{T}}, g::SHPGlyph) where {T}

    svgsegments = SVGPaths.SVGPathSegment{:rel,T}[]
    ctx = SHPPaths.SHPContext{T}()
    shpglyph_to_svgsegments(ctx, svgsegments, g)
    if !(ctx.dx ≈ 0 && ctx.dy ≈ 0)
        push!(svgsegments, SVGPaths.MoveToRel{T}(ctx.dx, -ctx.dy))
    end
    SVGPaths.SVGPath(svgsegments)
end
