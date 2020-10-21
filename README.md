# FunctionWranglers.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Build Status](https://travis-ci.com/tisztamo/FunctionWranglers.jl.svg?branch=master)](https://travis-ci.com/tisztamo/FunctionWranglers.jl)
[![codecov.io](http://codecov.io/github/tisztamo/FunctionWranglers.jl/coverage.svg?branch=master)](http://codecov.io/github/tisztamo/FunctionWranglers.jl?branch=master)

This package allows fast, inlined execution of functions provided in an array.

The following operations are supported:

# smap!

`smap!` maps a value using all the functions into a preallocated array. 

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

julia> smap!(result, w, 10.0)

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

Please note that merging the method bodies at the first call have some compilation overhead, which may be significant if the array contains more than a few dozen functions. Tests run with 200 functions.
