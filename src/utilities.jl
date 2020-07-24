
function to_utf8io(io::IO)
    utfio = IOBuffer()
    for c in read(io)
        if c < 0x20
            c in (0x09, 0x0a, 0x0d) || return nothing
        elseif 0x7f <= c < 0xa0
            return nothing
        end
        write(utfio, Char(c)) # ISO 8859-1 to UTF-8
    end
    seekstart(utfio)
    return utfio
end