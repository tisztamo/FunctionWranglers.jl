# FunctionWranglers.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Build Status](https://travis-ci.com/tisztamo/FunctionWranglers.jl.svg?branch=master)](https://travis-ci.com/tisztamo/FunctionWranglers.jl)
[![codecov.io](http://codecov.io/github/tisztamo/FunctionWranglers.jl/coverage.svg?branch=master)](http://codecov.io/github/tisztamo/FunctionWranglers.jl?branch=master)

This micropackage allows fast, inlined execution of function bodies provided in an array.

Currently only the `smap!` operaion is implemented, which maps a value using all the functions into a preallocated array. (s in `smap!` means either static or swapped, as the operation is similar to `map`, but here a single value is mapped with a lot of functions)

```julia
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.5.1 (2020-08-25)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> using FunctionWranglers

julia> create_adder(value) = (x) -> x + value
create_adder (generic function with 1 method)

julia> adders = [create_adder(i) for i = 1:5]
5-element Array{var"#1#2"{Int64},1}:
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)
 #1 (generic function with 1 method)

julia> w = FunctionWrangler(adders)
FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{Nothing,Nothing}}}}}}(var"#1#2"{Int64}(1), FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{Nothing,Nothing}}}}}(var"#1#2"{Int64}(2), FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{Nothing,Nothing}}}}(var"#1#2"{Int64}(3), FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{Nothing,Nothing}}}(var"#1#2"{Int64}(4), FunctionWrangler{var"#1#2"{Int64},FunctionWrangler{Nothing,Nothing}}(var"#1#2"{Int64}(5), FunctionWrangler{Nothing,Nothing}(nothing, nothing))))))

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
  2.892 ns (0 allocations: 0 bytes)
```

Please note that merging the function bodies at the first call have some compilation overhead, which may be significant if the array contains more than a few hundred functions.