module Paths

abstract type Path end

abstract type PathSegment end

export Path, PathSegment
export SHPPaths, SHPPath
export SVGPaths, SVGPath

function bulge end
function dx end
function dy end

include("shppaths.jl")
include("svgpaths.jl")

end # module
