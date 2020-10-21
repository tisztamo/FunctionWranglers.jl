module FunctionWranglers

export FunctionWrangler, smap!, sfindfirst, sreduce, railway

import Base: length, show

struct FunctionWrangler{TOp, TNext}
    op::TOp
    next::TNext
end

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

# Using variable argument definitions sometimes caused the compiler to "loose track" of type information
# and generate slow code (tested up to 1.5.1 with https://gist.github.com/tisztamo/1ce6632d7e6ffc4
# @generate-ing solves the issue
@inline @generated function _smap!(outputs, wrangler::FunctionWrangler{TOp, TNext}, myidx, args...) where {TNext, TOp}
    TOp === Nothing && return :(nothing)
    argnames = [:(args[$i]) for i = 1:length(args)]
    return quote
        outputs[myidx] = wrangler.op($(argnames...))
        return _smap!(outputs, wrangler.next, myidx + 1, $(argnames...))
    end
end

smap!(outputs, wrangler::FunctionWrangler, args...) = _smap!(outputs, wrangler, 1, args...)

@inline @generated function _sfindfirst(wrangler::FunctionWrangler{TOp, TNext}, myidx, args...) where {TNext, TOp}
    TOp === Nothing && return :(nothing)
    argnames = [:(args[$i]) for i = 1:length(args)]
    return quote
        if wrangler.op($(argnames...)) === true
            return myidx
        end
        return _sfindfirst(wrangler.next, myidx + 1, $(argnames...))            
    end
end

sfindfirst(wrangler::FunctionWrangler, args...) = _sfindfirst(wrangler, 1, args...)

@inline @generated function _sreduce(wrangler::FunctionWrangler{TOp, TNext}, myidx, prev, args...; init = nothing) where {TNext, TOp}
    TOp === Nothing && return :(prev)
    argnames = [:(args[$i]) for i = 1:length(args)]
    return quote
        current = wrangler.op(prev, $(argnames...))
        return _sreduce(wrangler.next, myidx + 1, current, $(argnames...))            
    end
end

sreduce(wrangler::FunctionWrangler, args...; init = nothing) = _sreduce(wrangler, 1, init, args...)

@inline @generated function _railway(wrangler::FunctionWrangler{TOp, TNext}, myidx, prev, args...; iserror) where {TNext, TOp}
    TOp === Nothing && return :(prev)
    argnames = [:(args[$i]) for i = 1:length(args)]
    return quote
        current = wrangler.op(prev, $(argnames...))
        iserror(current) && return current
        return _railway(wrangler.next, myidx + 1, current, $(argnames...); iserror)            
    end
end

function railway(wrangler::FunctionWrangler, input, args...; iserror = isnothing)
    return _railway(wrangler, 1, input, args...; iserror)
end

end # module
