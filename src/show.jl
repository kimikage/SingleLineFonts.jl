
function Base.show(io::IO, mime::MIME"image/svg+xml", g::SHPGlyph)
    em = g.font.above + g.font.below
    margin = em / 2
    em2 = 2em
    ox = margin + (g.vertical ? em / 2 : 0)
    oy = margin + (g.vertical ? 0 : g.font.above)
    write_declaration(io, mime)
    write(io, """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="25mm" height="25mm"
             viewBox="0 0 $em2 $em2" style="fill:none;stroke:currentColor;stroke-width:0.5">
        """)

    svgpath = convert(SVGPaths.SVGPath{Float64}, g)
    write(io, """
        <g transform="translate($ox, $oy)">
            <path d="$(svgpath.d)" />
        </g>
        """)
    write(io, """
        </svg>
        """)
end

function write_declaration(io::IO, ::MIME"image/svg+xml")
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        """)
end
