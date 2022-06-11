using Test
using PolyBranch
using IfElse

# we would like control flow to be polymorphic, 
# for example to let `AbstractFloat` guards take the weighted average of both branches
IfElse.ifelse(guard::AbstractFloat, then, elze) = guard*then + (1-guard)*elze

@testset "weighted average if-then-else" begin
    
    # a function with control flow
    function foo(x,y)
        z = y*0.5
        if x
            0.4 + z
        else
            0.1 + z
        end
    end

    # control flow depending on `Bool`` guards works by default
    @test foo(true, 0.1) ≈ 0.45

    # control flow depending on such `AbstractFloat` guards is not polymorphic by default
    @test_throws TypeError foo(0.9, 0.1) # ERROR: TypeError: non-boolean (Float64) used in boolean context

    # `Bool` guards still work (and evaluate only a single branch)
    @test polybranch() do 
        foo(true, 0.1) 
    end ≈ 0.45

    # `AbstractFloat`` guards now also work
    @test polybranch() do 
        foo(0.4, 0.1) 
    end ≈ 0.27

end

@testset "weighted average if-then-zero-else-seven" begin

    function zero_or_seven(cond)
        if cond
            0
        else
            7
        end
    end

    zero_or_seven2(cond) = polybranch() do 
        zero_or_seven(cond) 
    end

    # `Bool` guards still work
    @test zero_or_seven2(true) ≈ 0
    @test zero_or_seven2(false) ≈ 7

    # `AbstractFloat`` guards now also work
    @test zero_or_seven2(1.) ≈ 0
    @test zero_or_seven2(0.) ≈ 7
    @test zero_or_seven2(0.4) ≈ 0.6 * 7
end

@testset "weighted average if-then-zero-else-seven-with-identity" begin
    function zero_or_seven(cond)
        if cond
            identity(0)
        else
            identity(7)
        end
    end

    zero_or_seven2(cond) = polybranch() do 
        zero_or_seven(cond) 
    end

    # `Bool` guards still work
    @test zero_or_seven2(true) ≈ 0
    @test zero_or_seven2(false) ≈ 7

    # `AbstractFloat`` guards now also work
    @test zero_or_seven2(1.) ≈ 0
    @test zero_or_seven2(0.) ≈ 7
    @test zero_or_seven2(0.4) ≈ 0.6 * 7
end

@testset "weighted average recursive" begin
    
    # expected number of `true` sampled coins at start of list
    function num_true(x)
        if !isempty(x) && x[1]
            1 + num_true(x[2:end])
        else
            0
        end
    end

    @test_throws TypeError num_true([0.2, 0.9]) # ERROR: TypeError: non-boolean (Float64) used in boolean context

    num_true2(x) = polybranch() do 
        num_true(x) 
    end

    @test num_true2([]) ≈ 0
    @test num_true2([0.2]) ≈ 0.2
    @test num_true2([0.2, 0.9]) ≈ 0.38# 0.2*(1-0.9)*1 + 0.2*0.9*2 = 0.38
    @test num_true2([0.2, 0.9, 0.4]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452
    @test num_true2([0.2, 0.9, 0.4, 0.0]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452

end

@testset "weighted average while" begin
    
    # expected number of `true` sampled coins at start of list
    function num_true(x)
        size = 0
        while !isempty(x) && x[1]
            x = x[2:end]
            size += 1
        end
        size
    end

    @test_throws TypeError num_true([0.2, 0.9]) # ERROR: TypeError: non-boolean (Float64) used in boolean context

    num_true2(x) = polybranch() do 
        num_true(x) 
    end

    @test num_true2([]) ≈ 0
    @test num_true2([0.2]) ≈ 0.2
    @test num_true2([0.2, 0.9]) ≈ 0.38# 0.2*(1-0.9)*1 + 0.2*0.9*2 = 0.38
    @test num_true2([0.2, 0.9, 0.4]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452
    @test num_true2([0.2, 0.9, 0.4, 0.0]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452

end