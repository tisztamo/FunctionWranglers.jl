using FunctionWranglers
using Test

const TEST_LENGTH = 200

create_adder1(a) = x -> x + a
create_adder2(a1, a2) = (x, y) -> x + a1 + y + a2
create_adder3(a1, a2, a3) = (x, y, z) -> x + a1 + y + a2 + z + a3

test_data1 = 1000.0
test_data2 = 2000.0
test_data3 = 3000.0

@testset "basics" begin
    adders = Function[create_adder1(i) for i = 1:TEST_LENGTH]
    @time w = FunctionWrangler(adders) # Time to create the nested list of types
    @test length(w) == TEST_LENGTH
    io = IOBuffer()
    show(io, MIME"text/plain"(), w)
    @test occursin(string(TEST_LENGTH), String(take!(io)))
    result = zeros(Float64, length(adders))
    @time smap!(result, w, test_data1) # Time to compile the merged body
    for i = 1:length(adders)
        @test adders[i](test_data1) == result[i]
    end
    #@btime smap!($result, $w, d) setup = (d = rand()) # Time to execute the merged fns
end

@testset "smap! multiple arguments" begin
    adders2 = [create_adder2(i, 2 * i) for i = 1:TEST_LENGTH]
    w = FunctionWrangler(adders2)
    result = zeros(Float64, length(adders2))
    smap!(result, w, test_data1, test_data2)
    for i = 1:length(adders2)
        @test adders2[i](test_data1, test_data2) == result[i]
    end

    adders3 = [create_adder3(i, 2 * i, 3 * i) for i = 1:TEST_LENGTH]
    w = FunctionWrangler(adders3)
    result = zeros(Float64, length(adders3))
    smap!(result, w, test_data1, test_data2, test_data3)
    for i = 1:length(adders3)
        @test adders3[i](test_data1, test_data2, test_data3) == result[i]
    end
end

@testset "sfindfirst" begin
    predicates = Function[() -> false for i=1:TEST_LENGTH]
    wp1 = FunctionWrangler(predicates)
    @test isnothing(sfindfirst(wp1)) == true

    push!(predicates, () -> true)
    wp2 = FunctionWrangler(predicates)
    @test isnothing(sfindfirst(wp1)) == true
    @test sfindfirst(wp2) == TEST_LENGTH + 1

    push!(predicates, () -> true)
    wp3 = FunctionWrangler(predicates)
    @test sfindfirst(wp3) == TEST_LENGTH + 1
end

@testset "sindex" begin
    fns = Function[create_adder1(1), create_adder2(2, 3), create_adder3(4, 5, 6)]
    w = FunctionWrangler(fns)
    @test sindex(w, 1, 10) == 11
    @test sindex(w, 2, 10, 20) == 10 + 2 + 20 + 3
    @test sindex(w, 3, 10, 20, 30) == 10 + 4 + 20 + 5 + 30 + 6
end

@testset "sreduce" begin
    fs = Function[create_adder1(1) for i = 1:TEST_LENGTH]
    wf1 = FunctionWrangler(fs)
    @test sreduce(wf1; init = 0) == TEST_LENGTH
    @test sreduce(wf1; init = 100) == 100 + TEST_LENGTH
    
    empty = Function[]
    wf2 = FunctionWrangler(empty)
    @test sreduce(wf2; init = 102) == 102
end

@inline gate(x, threshold) = x > threshold ? x : ConcreteFail()
creategate(threshold) = (x) -> gate(x, threshold) 

struct ConcreteFail <: Fail end

@testset "railway" begin
    gates2 = Function[x -> 1.0 * x, x ->Int(x), [creategate(i) for i=1:TEST_LENGTH]..., x -> 1.0 * x]
    fwg2 = FunctionWrangler(gates2)
    for i = 1:TEST_LENGTH
        @test railway(fwg2, i) isa Fail
    end
    @test railway(fwg2, TEST_LENGTH + 1) === TEST_LENGTH + 1.0
end