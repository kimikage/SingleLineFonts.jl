module SingleLineFontsGraphicExt

isdefined(Base, :get_extension) ? (using Graphics) : (using ..Graphics)

struct ContextWithSingleLineFonts{CTX <: GraphicContext} <: GraphicContext
    context::CTX
    font::SingleLineFont
    fontcache::Dict{String, SingleLineFont}
end

end # module
