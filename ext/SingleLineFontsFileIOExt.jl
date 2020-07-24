module SingleLineFontsFileIOExt

isdefined(Base, :get_extension) ? (using FileIO) : (using ..FileIO)

using UUIDs
using SingleLineFonts

const idSingleLineFonts = :SingleLineFonts => UUID("bcf3f819-ef0c-4e0a-904c-ac2eea82d9f5")

function SingleLineFonts.add_formats()
    SingleLineFontsFileIOExt.add_format_shp()
end

function SingleLineFonts.load(f::File{format"SHPFont"}; kwargs...)
    open(f, "r") do s
        return load(s; kwargs...)
    end
end

function SingleLineFonts.load(s::Stream{format"SHPFont"}; kwargs...)
    return SingleLineFonts.read_shp(stream(s))
end

is_not_esri(io::IO) = peek(io) != 0x00

function SingleLineFonts.add_format_shp()
    add_format(format"SHPFont", is_not_esri, ".shp", [idSingleLineFonts])
end


end # module
