using Stheno: CrossKernel, ZeroKernel, OneKernel, ConstKernel, CustomMean, pw
using Stheno: EQ, Exp, Linear, Noise, PerEQ
using FillArrays, LinearAlgebra

@testset "kernel" begin

    @testset "base kernels" begin
        rng, N, N′, D = MersenneTwister(123456), 5, 6, 2
        x0, x1, x2 = randn(rng, N), randn(rng, N), randn(rng, N′)
        x0_r, x1_r = range(-5.0, step=1, length=N), range(-4.0, step=1, length=N)
        x2_r, x3_r = range(-5.0, step=2, length=N), range(-3.0, step=1, length=N′)
        x4_r = range(-2.0, step=2, length=N′)

        X0 = ColsAreObs(randn(rng, D, N))
        X1 = ColsAreObs(randn(rng, D, N))
        X2 = ColsAreObs(randn(rng, D, N′))

        ȳ, Ȳ, Ȳ_sq = randn(rng, N), randn(rng, N, N′), randn(rng, N, N)

        @testset "ZeroKernel" begin
            @test map(ZeroKernel(), x0) isa Zeros
            @test map(ZeroKernel(), x0, x1) isa Zeros
            @test pw(ZeroKernel(), x0) isa Zeros
            @test pw(ZeroKernel(), x0, x2) isa Zeros
            differentiable_kernel_tests(ZeroKernel(), ȳ, Ȳ, Ȳ_sq, x0, x1, x2)
            differentiable_kernel_tests(ZeroKernel(), ȳ, Ȳ, Ȳ_sq, X0, X1, X2)
        end

        @testset "OneKernel" begin
            @test map(OneKernel(), x0) isa Ones
            @test map(OneKernel(), x0, x1) isa Ones
            @test pw(OneKernel(), x0) isa Ones
            @test pw(OneKernel(), x0, x2) isa Ones
            differentiable_kernel_tests(OneKernel(), ȳ, Ȳ, Ȳ_sq, x0, x1, x2)
            differentiable_kernel_tests(OneKernel(), ȳ, Ȳ, Ȳ_sq, X0, X1, X2)
        end

        @testset "ConstKernel" begin
            @test map(ConstKernel(5), x0) == 5 .* ones(length(x0))
            @test map(ConstKernel(5), x0) isa Fill
            @test map(ConstKernel(5), x0, x1) isa Fill
            @test pw(ConstKernel(5), x0) isa Fill
            @test pw(ConstKernel(5), x0, x2) isa Fill
            differentiable_kernel_tests(ConstKernel(5.0), ȳ, Ȳ, Ȳ_sq, x0, x1, x2)
            differentiable_kernel_tests(ConstKernel(5.0), ȳ, Ȳ, Ȳ_sq, X0, X1, X2)
        end

        @testset "EQ" begin
            @test map(EQ(), x0) isa Ones
            differentiable_kernel_tests(EQ(), ȳ, Ȳ, Ȳ_sq, x0, x1, x2)
            differentiable_kernel_tests(EQ(), ȳ, Ȳ, Ȳ_sq, X0, X1, X2)
            stationary_kernel_tests(EQ(), x0_r, x1_r, x2_r, x3_r, x4_r)
        end

        @testset "PerEQ" begin
            @test map(PerEQ(), x0) isa Ones
            differentiable_kernel_tests(PerEQ(), ȳ, Ȳ, Ȳ_sq, x0, x1, x2; atol=1e-6)
            stationary_kernel_tests(PerEQ(), x0_r, x1_r, x2_r, x3_r, x4_r)
        end

        @testset "Exp" begin
            @test map(Exp(), x0) isa Ones
            differentiable_kernel_tests(Exp(), ȳ, Ȳ, Ȳ_sq, x0 .+ 1, x1, x2)
            stationary_kernel_tests(Exp(), x0_r, x1_r, x2_r, x3_r, x4_r)
        end

        @testset "Linear" begin
            differentiable_kernel_tests(Linear(), ȳ, Ȳ, Ȳ_sq, x0, x1, x2)
            differentiable_kernel_tests(Linear(), ȳ, Ȳ, Ȳ_sq, X0, X1, X2)
        end

        @testset "Noise" begin
            @test pw(Noise(), x0, x0) == zeros(length(x0), length(x0))
            @test pw(Noise(), x0) == Diagonal(ones(length(x0)))
        end
    end

    @testset "(is)zero" begin
        @test zero(ZeroKernel()) == ZeroKernel()
        @test zero(EQ()) == ZeroKernel()
        @test iszero(ZeroKernel()) == true
        @test iszero(EQ()) == false
    end

    # # Tests for Rational Quadratic (RQ) kernel.
    # @test isstationary(RQ)
    # @test RQ(1.0)(1.0, 1.0) == 1
    # @test RQ(100.0)(1.0, 1000.0) ≈ 0
    # @test RQ(1.0) == RQ(1.0)
    # @test RQ(1.0) == RQ(1)
    # @test RQ(1.0) != RQ(5.0)
    # @test RQ(1000.0) != EQ()

    # # Tests for Polynomial kernel.
    # @test !isstationary(Poly)
    # @test Poly(2, -1.0)(1.0, 1.0) == 0.0
    # @test Poly(5, -1.0)(1.0, 1.0) == 0.0
    # @test Poly(5, 0.0)(1.0, 1.0) == 1.0
    # @test Poly(5, 0.0) == Poly(5, 0.0)
    # @test Poly(2, 1.0) != Poly(5, 1.0)

    # # Tests for Wiener kernel.
    # @test !isstationary(Wiener)
    # @test Wiener()(1.0, 1.0) == 1.0
    # @test Wiener()(1.0, 1.5) == 1.0
    # @test Wiener()(1.5, 1.0) == 1.0
    # @test Wiener() == Wiener()
    # @test Wiener() != Noise()

    # # Tests for WienerVelocity.
    # @test !isstationary(WienerVelocity)
    # @test WienerVelocity()(1.0, 1.0) == 1 / 3
    # @test WienerVelocity() == WienerVelocity()
    # @test WienerVelocity() != Wiener()
    # @test WienerVelocity() != Noise()
end
