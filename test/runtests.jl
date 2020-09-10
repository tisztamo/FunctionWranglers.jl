using FunctionWranglers
using Test

const TEST_LENGTH = 200

create_adder1(a) = (x) -> x + a
create_adder2(a1, a2) = (x, y) -> x + a1 + y + a2
create_adder3(a1, a2, a3) = (x, y, z) -> x + a1 + y + a2 + z + a3

test_data1 = 1000.0
test_data2 = 2000.0
test_data3 = 3000.0

@testset "basics" begin
    adders = [create_adder1(i) for i = 1:TEST_LENGTH]
    @time w = FunctionWrangler(adders) # Time to create the nested list of types
    @test length(w) == TEST_LENGTH
    io = IOBuffer()
    show(io, MIME"text/plain"(), w)
    @test contains(String(take!(io)), string(TEST_LENGTH))
    result = zeros(Float64, length(adders))
    @time smap!(result, w, test_data1) # Time to compile the merged body
    for i = 1:length(adders)
        @test adders[i](test_data1) == result[i]
    end
    #@btime smap!($result, $w, d) setup = (d = rand()) # Time to execute the merged fns
end

@testset "multiple arguments" begin
    adders2 = [create_adder2(i, 2 * i) for i = 1:200]
    w = FunctionWrangler(adders2)
    result = zeros(Float64, length(adders2))
    smap!(result, w, test_data1, test_data2)
    for i = 1:length(adders2)
        @test adders2[i](test_data1, test_data2) == result[i]
    end

    adders3 = [create_adder3(i, 2 * i, 3 * i) for i = 1:200]
    w = FunctionWrangler(adders3)
    result = zeros(Float64, length(adders3))
    smap!(result, w, test_data1, test_data2, test_data3)
    for i = 1:length(adders3)
        @test adders3[i](test_data1, test_data2, test_data3) == result[i]
    end
end
