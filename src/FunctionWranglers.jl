module FunctionWranglers

export FunctionWrangler, smap!

import Base: length, show

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

Base.show(io::IO, ::MIME"text/plain", w::FunctionWrangler) = begin
    print(io, "FunctionWrangler with $(length(w)) items: ")
    iw = w
    while !isnothing(iw.op)
        print(io, string(iw.op) * ", ")
        iw = iw.next
    end
    return nothing
end

@inline function _smap!(outputs, wrangler::FunctionWrangler{TOp, TNext}, myidx,  p1) where {TNext, TOp}
    if TOp === Nothing
        return nothing
    end
    outputs[myidx] = wrangler.op(p1)
    return _smap!(outputs, wrangler.next, myidx + 1, p1)
end

# Using variable argument definitions sometimes caused the compiler to "loose track" of type information
# and generate slow code (tested up to 1.5.1 with https://gist.github.com/tisztamo/1ce6632d7e6ffc45488df26dacff64dd)
@inline function _smap!(outputs, wrangler::FunctionWrangler{TOp, TNext}, myidx,  p1, p2) where {TNext, TOp}
    if TOp === Nothing
        return nothing
    end
    outputs[myidx] = wrangler.op(p1, p2)
    return _smap!(outputs, wrangler.next, myidx + 1, p1, p2)
end

@inline function _smap!(outputs, wrangler::FunctionWrangler{TOp, TNext}, myidx,  p1, p2, p3) where {TNext, TOp}
    if TOp === Nothing
        return nothing
    end
    outputs[myidx] = wrangler.op(p1, p2, p3)
    return _smap!(outputs, wrangler.next, myidx + 1, p1, p2, p3)
end

smap!(outputs, wrangler::FunctionWrangler, args...) = _smap!(outputs, wrangler, 1, args...)

end
