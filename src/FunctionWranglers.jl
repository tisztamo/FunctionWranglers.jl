module FunctionWranglers

export FunctionWrangler, smap!

import Base.length

struct FunctionWrangler{TOp, TNext}
    op::TOp
    next::TNext
end # module

function FunctionWrangler(fns)
    if length(fns) == 0
        return FunctionWrangler(nothing, nothing)
    end
    next = FunctionWrangler(fns[2:end])
    return FunctionWrangler(fns[1], next)
end

Base.length(w::FunctionWrangler) = isnothing(w.op) ? 0 : 1 + length(w.next)

function _smap!(outputs, wrangler::FunctionWrangler{TOp, TNext}, myidx, args...) where {TNext, TOp}
    if TOp === Nothing
        return nothing
    end
    outputs[myidx] = wrangler.op(args...)
    _smap!(outputs, wrangler.next, myidx + 1, args...)
    return nothing
end

smap!(outputs, wrangler::FunctionWrangler, args...) = _smap!(outputs, wrangler, 1, args...)

end
