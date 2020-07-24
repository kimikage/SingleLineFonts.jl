module SingleLineFonts

if !isdefined(Base, :get_extension)
    using Requires
end

import Base: show, convert

export SingleLineFont, SHPFont
export read_singlelinefont


include("utilities.jl")

abstract type SingleLineFont end

include("paths/paths.jl")

using .Paths
import .Paths: SHPPaths, SVGPaths
import .SHPPaths: SHPPath
import .SVGPaths: SVGPath

struct ParseError <: Exception
    msg::String
end


include("null.jl")
include("shp.jl")
# include("shx.jl")
include("conversions.jl")
include("geom_conversions.jl")
include("show.jl")


function read_singlelinefont(filepath::AbstractString)
    open(filepath, "r") do f
        read_font(f)
    end
end

function read_singlelinefont(io::IO)
    b0 = peek(io)
    if b0 === 0x41 # 'A' of "AutoCAD"
        error("not supported")
        # return read_shx(io)
    else
        utfio = to_utf8io(io)
        if utfio isa IO
            return _read_shp_utf8(io)
        end
    end
    error("unknown format")
end

function load end
function save end

function add_formats end
function add_format_shp end
function add_format_shx end


@static if !isdefined(Base, :get_extension)
    function __init__()
        @require FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" include("../ext/SingleLineFontsFileIOExt.jl")
        @require Graphics = "a2bd30eb-e257-5431-a919-1863eab51364" include("../ext/SingleLineFontsGraphicsExt.jl")
    end
end

end # module
