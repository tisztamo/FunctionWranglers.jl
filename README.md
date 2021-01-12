# FunctionWranglers.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-green.svg)
[![Build Status](https://travis-ci.com/tisztamo/FunctionWranglers.jl.svg?branch=master)](https://travis-ci.com/tisztamo/FunctionWranglers.jl)
[![codecov.io](http://codecov.io/github/tisztamo/FunctionWranglers.jl/coverage.svg?branch=master)](http://codecov.io/github/tisztamo/FunctionWranglers.jl?branch=master)

This package allows fast, inlined execution of functions provided in an array. It can be used to speed up some calculations directly, or as the base of high-performance programming primitives.

The following operations are supported currently:

- `smap!` maps a single set of arguments using all the functions into a preallocated array. 
- `sfindfirst` looks for the first function which returns `true` for the given arguments, and returns its index.
- `sreduce` transforms a single value with the composite of the functions, and also allows providing extra "context" arguments to the functions

Please note that merging the method bodies at the first call have some compilation overhead, which may be significant if the array contains more than a few dozen functions. Tests run with 200 functions.

#### smap!

    smap!(outputs, wrangler::FunctionWrangler, args...)

Map a single set of arguments using all the functions into a preallocated array.

```julia
  | | |_| | | | (_| |  |  Version 1.5.2 (2020-09-23)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/ 

julia> using FunctionWranglers

julia> create_adder(value) = (x) -> x + value
create_adder (generic function with 1 method)

julia> adders = Function[create_adder(i) for i = 1:5]
5-element Array{Function,1}:
 #3 (generic function with 1 method)
 #3 (generic function with 1 method)
 #3 (generic function with 1 method)
 #3 (generic function with 1 method)
 #3 (generic function with 1 method)

julia> w = FunctionWrangler(adders)
FunctionWrangler with 5 items: #3, #3, #3, #3, #3, 

julia> result = zeros(Float64, length(adders))
5-element Array{Float64,1}:
 0.0
 0.0
 0.0
 0.0
 0.0

julia> smap!(result, w, 10.0) # If your functions accept more arguments, you can also provide them here

julia> result
5-element Array{Float64,1}:
 11.0
 12.0
 13.0
 14.0
 15.0

julia> @btime smap!($result, $w, d) setup = (d = rand())
  3.934 ns (0 allocations: 0 bytes)
```


#### sfindfirst

    sfindfirst(wrangler::FunctionWrangler, args...)

Look for the first function which returns `true` for the given arguments, and return its index. Return `nothing` if no function resulted in `true`.

```

julia> using FunctionWranglers, BenchmarkTools

julia> predicates = Function[(x) -> x < i for i=1:5]
5-element Array{Function,1}:
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)

julia> fw = FunctionWrangler(predicates)
FunctionWrangler with 5 items: #1, #1, #1, #1, #1, 

julia> sfindfirst(fw, 4)
5

julia> sfindfirst(fw, 5)

julia> @btime sfindfirst($fw, 4)
  1.699 ns (0 allocations: 0 bytes)
5
```

#### sreduce

    sreduce(wrangler::FunctionWrangler, args...; init = nothing)

Transform a single `init` value with the composite of the functions in `wrangler`.

The functions will be applied in their order in `wrangler`. If you provide extra args, they will be passed to the functions after the current value of the computation:

```
julia> using FunctionWranglers, BenchmarkTools

julia> pluses = Function[(+) for i = 1:5]
5-element Array{Function,1}:
 + (generic function with 184 methods)
 + (generic function with 184 methods)
 + (generic function with 184 methods)
 + (generic function with 184 methods)
 + (generic function with 184 methods)

julia> fw = FunctionWrangler(pluses)
FunctionWrangler with 5 items: +, +, +, +, +, 

julia> sreduce(fw, 1; init = 10)
15

julia> @btime sreduce($fw, 1; init = 10)
  1.099 ns (0 allocations: 0 bytes)
15
```
