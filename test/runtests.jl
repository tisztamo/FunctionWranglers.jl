using FunctionWranglers
using Test

create_adder(value) = (x) -> x + value

const test_data = 10.0

@testset "basics" begin
    adders = [create_adder(i) for i = 1:200]
    @time w = FunctionWrangler(adders) # Time to create the nested list of types
    @test length(w) == length(adders)
    result = zeros(Float64, length(adders))
    @time smap!(result, w, test_data) # Time to compile the merged body
    for i = 1:length(adders)
        @test adders[i](test_data) == result[i]
    end
    #@btime smap!($result, $w, d) setup = (d = rand()) # Time to execute the merged fns
end
