# Note that "SHP" means AutoCAD SHP file, not ESRI Shapefile for GIS.

struct SHPShape{T <: Union{UInt8, UInt16}}
    name::String
    shape::SHPPaths.SHPPath{T}
end

struct SHPFont{T <: Union{UInt8, UInt16}} <: SingleLineFont
    name::String
    above::UInt8
    below::UInt8
    shapes::Dict{T, SHPShape{T}}
    header_comment::String
end

struct SHPGlyph{T <: Union{UInt8, UInt16}}
    font::SHPFont
    codeunit::T
    vertical::Bool
end

function glyph(font::SHPFont{T}, codeunit::T; vertical::Bool=false) where {T}
    SHPGlyph(font, codeunit, vertical)
end

# io
function read_shp(filepath::AbstractString)
    open(filepath, "r") do f
        read_shp(f)
    end
end

function read_shp(io::IO)
    utf8io = to_utf8io(io)
    utf8io isa IO || throw(ParseError("invalid format"))
    return _read_shp_utf8(utf8io)
end

function _read_shp_utf8(io::IO)
    fonttype = ""
    fontname = ""
    above, below, modes, encoding, type = 0, 0, 0, 0, 0
    header_comment = IOBuffer()
    defbytes, shapenumber, shapename = 0, -1, ""
    specbytes = IOBuffer()
    shapes = Dict{UInt16,SHPShape{UInt16}}()
    for (ln, line) in enumerate(eachline(io))
        m = match(r"^([^;]{0,128})(.*)", line) # strip comment
        m === nothing && break
        statement, comment = m.captures
        if defbytes < 1
            write(header_comment, comment, "\r\n")
        end
        m = match(r"^\s*\*([^,\s]+)\s*,\s*([0-9a-fA-F]+)\s*,\s*([^,]*)", statement)
        if m === nothing
            write(specbytes, statement)
            eof(io) || continue
        end
        if defbytes > 0
            specstr = String(take!(specbytes))
            if shapenumber > 0
                path = parse(SHPPaths.SHPPath{UInt16}, specstr)
                push!(shapes, shapenumber % UInt16 => SHPShape{UInt16}(shapename, path))
            else # Unicode Font Descriptions
                values = split(specstr, r"\s*[()]?\s*,\s*[()]?\s*"s)
                numbers = SHPPaths.parse_shp_number.(filter!(s -> !isempty(s), values))
                above, below, modes, encoding, type, _ = numbers .% UInt8
            end
            eof(io) && break
        end
        snumber, dbytes, shapename = m.captures
        defbytes = SHPPaths.parse_shp_number(dbytes)
        if fonttype == "UNIFONT"
            shapenumber = SHPPaths.parse_shp_number(snumber)
        else
            if snumber != "UNIFONT"
                throw(ParseError("unsupported format: $snumber (line: $ln)"))
            end
            fonttype = snumber
            if defbytes != 6
                throw(ParseError("invalid defbytes: $dbytes (line: $ln)"))
            end
            fontname = String(shapename)
        end
    end
    SHPFont(fontname, above, below, shapes, String(take!(header_comment)))
end
