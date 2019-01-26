using Random, LinearAlgebra, BlockArrays, FillArrays
using BlockArrays: cumulsizes

@testset "block_arrays" begin

    # Test construction of `BlockVector` from a vector of vectors. Also test copying.
    let
        rng, N, N′ = MersenneTwister(123456), 5, 6
        x, x′ = randn(rng, N), randn(rng, N′)
        x̂ = BlockVector([x, x′])
        @test length(x̂) == N + N′
        @test x̂ == vcat(x, x′)
        @test getblock(x̂, 1) == x && getblock(x̂, 2) == x′

        # Test BlockVector construction adjoint.
        adjoint_test(x->BlockVector([x]), BlockVector([randn(rng, N)]), x)
        adjoint_test(x->BlockVector([x]), randn(rng, N), x)

        adjoint_test(
            x->BlockVector([x, x′]),
            BlockVector([randn(rng, N), randn(rng, N′)]),
            x,
        )
        adjoint_test(x->BlockVector([x, x′]), randn(rng, N + N′), x)

        # Test BlockVector conversion to Vector adjoint.
        adjoint_test(Vector, randn(rng, N), BlockVector([x]))
        adjoint_test(Vector, randn(rng, N + N′), x̂)

        # zero of a BlockVector should be a BlockVector
        @test zero(x̂) isa BlockVector
        @test cumulsizes(x̂) == cumulsizes(zero(x̂))
        @test zero(x̂) == zero(Vector(x̂))
    end

    # Test construction of `BlockMatrix` from matrix of matrices. Also test copying.
    let
        rng, P1, P2, P3, Q1, Q2 = MersenneTwister(123456), 2, 3, 6, 4, 5
        X11, X12 = randn(rng, P1, Q1), randn(rng, P1, Q2)
        X21, X22 = randn(rng, P2, Q1), randn(rng, P2, Q2)
        X31, X32 = randn(rng, P3, Q1), randn(rng, P3, Q2)
        X = BlockMatrix(reshape([X11, X21, X31, X12, X22, X32], 3, 2))
        @test size(X, 1) == P1 + P2 + P3
        @test size(X, 2) == Q1 + Q2
        @test getblock(X, 1, 1) == X11
        @test getblock(X, 1, 2) == X12
        @test getblock(X, 2, 1) == X21
        @test getblock(X, 2, 2) == X22

        @test cumulsizes(X, 1) == cumsum([1, P1, P2, P3])
        @test cumulsizes(X, 2) == cumsum([1, Q1, Q2])

        @test blocksizes(X, 1) == [P1, P2, P3]
        @test blocksizes(X, 2) == [Q1, Q2]

        @test BlockMatrix([X11, X21, X31, X12, X22, X32], 3, 2) == X

        Y = BlockMatrix([X11, X21, X31])
        @test size(Y, 1) == P1 + P2 + P3
        @test size(Y, 2) == Q1
        @test getblock(Y, 1, 1) == X11
        @test getblock(Y, 2, 1) == X21
        @test cumulsizes(Y, 1) == cumsum([1, P1, P2, P3])
        @test cumulsizes(Y, 2) == cumsum([1, Q1])

        @test blocksizes(Y, 1) == [P1, P2, P3]
        @test blocksizes(Y, 2) == [Q1]

        P, Q = P1 + P2 + P3, Q1 + Q2
        adjoint_test(
            X11->BlockMatrix(reshape([X11, X21, X31, X12, X22, X32], 3, 2)),
            randn(rng, P, Q),
            X11,
        )
        adjoint_test(
            X11->BlockMatrix(reshape([X11, X21, X31, X12, X22, X32], 3, 2)),
            X,
            X11,
        )
        adjoint_test(X11->BlockMatrix([X11, X21]), randn(rng, P1 + P2, Q1), X11)
        adjoint_test(X11->BlockMatrix([X11, X21]), BlockMatrix([X11, X21]), X11)
        adjoint_test(X11->BlockMatrix([X11, X12], 1, 2), BlockMatrix([X11, X12], 1, 2), X11)

        # BlockMatrix conversion to Matrix.
        adjoint_test(Matrix, randn(rng, size(X)), X)

        # zero of a BlockMatrix should be a BlockMatrix.
        @test zero(X) isa BlockMatrix
        @test cumulsizes(X) == cumulsizes(zero(X))
        @test zero(X) == zero(Matrix(X))
    end

    # # Test Symmetric block matrix construction and util.
    # let
    #     rng, P1, P2 = MersenneTwister(123456), 3, 4
    #     A11, A12, A22 = randn(rng, P1, P1), randn(rng, P1, P2), randn(rng, P2, P2)
    #     A_ = BlockMatrix([A11, zeros(Float64, P2, P1), A12, A22], 2, 2)
    #     A = Symmetric(A_)
    #     @test unbox(A) === A_
    #     @test Symmetric(A) === A
    #     @test nblocks(A) == nblocks(A_)
    #     @test nblocks(A, 1) == nblocks(A_, 1)
    #     @test nblocks(A, 2) == nblocks(A_, 2)
    #     @test blocksize(A, 1, 1) == blocksize(A_, 1, 1) &&
    #         blocksize(A, 1, 2) == blocksize(A_, 1, 2) &&
    #         blocksize(A, 2, 1) == blocksize(A_, 2, 1) &&
    #         blocksize(A, 2, 2) == blocksize(A_, 2, 2)
    #     @test size(A) == size(A_)
    #     @test getindex(A, 1, 2) == getindex(A_, 1, 2)
    #     @test eltype(A) == eltype(A_)

    #     @test getblock(A, 1, 1) === Symmetric(getblock(A_, 1, 1))
    #     @test getblock(A, 2, 1) == transpose(getblock(A_, 1, 2))
    #     @test getblock(A, 1, 2) === getblock(A_, 1, 2)
    #     @test getblock(A, 2, 2) == Symmetric(getblock(A_, 2, 2))
    # end

    # # Test triangular basics.
    # let
    #     rng, P1, P2 = MersenneTwister(123456), 3, 4
    #     A11, A12, A22 = randn(rng, P1, P1), randn(rng, P1, P2), randn(rng, P2, P2)
    #     A = BlockMatrix([A11, zeros(Float64, P2, P1), A12, A22], 2, 2)
    #     U, L = UpperTriangular(A), LowerTriangular(A)

    #     # UpperTriangular functionality.
    #     @test unbox(U) === A
    #     @test blocksize(U, 1, 1) == blocksize(A, 1, 1)
    #     @test blocksize(U, 2, 1) == blocksize(A, 2, 1)
    #     @test cumulsizes(U, 1) == cumulsizes(A, 1)
    #     @test cumulsizes(U, 2) == cumulsizes(A, 2)
    #     @test cumulsizes(U) == cumulsizes(A)

    #     @test getblock(U, 1, 1) == UpperTriangular(getblock(A, 1, 1))
    #     @test getblock(U, 2, 1) === Zeros{Float64}(P2, P1)
    #     @test getblock(U, 2, 2) == UpperTriangular(getblock(A, 2, 2))

    #     @test BlockMatrix(U) isa AbstractBlockMatrix
    #     @test Matrix(BlockMatrix(U)) == Matrix(U)

    #     # LowerTriangular functionality.
    #     @test unbox(L) === A
    #     @test blocksize(L, 1, 1) == blocksize(A, 1, 1)
    #     @test blocksize(L, 2, 1) == blocksize(A, 2, 1)
    #     @test cumulsizes(L, 1) == cumulsizes(A, 1)
    #     @test cumulsizes(L, 2) == cumulsizes(A, 2)
    #     @test cumulsizes(L) == cumulsizes(A)

    #     @test getblock(L, 1, 1) == LowerTriangular(getblock(A, 1, 1))
    #     @test getblock(L, 1, 2) === Zeros{Float64}(P1, P2)
    #     @test getblock(L, 2, 2) == LowerTriangular(getblock(A, 2, 2))

    #     @test BlockMatrix(L) isa AbstractBlockMatrix
    #     @test Matrix(BlockMatrix(L)) == Matrix(L)

    #     # Note the subtle difference here. This is correct.
    #     @test getblock(U, 1, 2) === getblock(A, 1, 2)
    #     @test getblock(L, 2, 1) == getblock(A, 2, 1)
    # end

    # # Test copying.
    # let
    #     # BlockVector
    #     rng, N, N′ = MersenneTwister(123456), 5, 6
    #     x, x′ = randn(rng, N), randn(rng, N′)
    #     x̂ = BlockVector([x, x′])

    #     @test copy(x̂) isa BlockVector
    #     @test copy(x̂) == x̂

    #     # BlockMatrix
    #     rng, P1, P2 = MersenneTwister(123456), 2, 3
    #     X11, X12 = randn(rng, P1, P1), randn(rng, P1, P2)
    #     X21, X22 = randn(rng, P2, P1), randn(rng, P2, P2)
    #     X = BlockMatrix(reshape([X11, X21, X12, X22], 2, 2))
    #     @test copy(X) isa BlockMatrix
    #     @test copy(X) == X

    #     # block-symmetric
    #     B = Symmetric(X)
    #     @test copy(B) isa Symmetric{T, <:AbstractBlockMatrix{T}} where T
    #     @test copy(B) == B

    #     # LowerTriangular
    #     L = LowerTriangular(X)
    #     @test copy(L) isa LowerTriangular{T, <:AbstractBlockMatrix{T}} where T
    #     @test copy(L) == L

    #     # UpperTriangular
    #     U = UpperTriangular(X)
    #     @test copy(U) isa UpperTriangular{T, <:AbstractBlockMatrix{T}} where T
    #     @test copy(U) == U
    # end

    # # Transposition
    # let
    #     # Regular block matrices
    #     rng, P1, P2, P3, Q1, Q2 = MersenneTwister(123456), 2, 3, 6, 4, 5
    #     X11, X12 = randn(rng, P1, Q1), randn(rng, P1, Q2)
    #     X21, X22 = randn(rng, P2, Q1), randn(rng, P2, Q2)
    #     X31, X32 = randn(rng, P3, Q1), randn(rng, P3, Q2)
    #     X = BlockMatrix(reshape([X11, X21, X31, X12, X22, X32], 3, 2))

    #     for foo in [adjoint, transpose]

    #         @test Matrix(foo(X)) == foo(Matrix(X))

    #         @test nblocks(foo(X), 1) == nblocks(X, 2)
    #         @test nblocks(foo(X), 2) == nblocks(X, 1)
    #         @test nblocks(foo(X)) == reverse(nblocks(X))

    #         @test cumulsizes(foo(X), 1) == cumulsizes(X, 2)
    #         @test cumulsizes(foo(X), 2) == cumulsizes(X, 1)

    #         @test size(foo(X), 1) == size(X, 2)
    #         @test size(foo(X), 2) == size(X, 1)
    #         @test size(foo(X)) == reverse(size(X))

    #         @test foo(foo(X)) == X
    #     end

    #     # Symmetric matrices should be invariant under transposition
    #     rng, P1, P2 = MersenneTwister(123456), 2, 3
    #     X11, X12 = randn(rng, P1, P1), randn(rng, P1, P2)
    #     X21, X22 = randn(rng, P2, P1), randn(rng, P2, P2)
    #     X = BlockMatrix(reshape([X11, X21, X12, X22], 2, 2))
    #     B = Symmetric(X)

    #     for foo in [adjoint, transpose]
    #         @test foo(B) isa BlockSymmetric
    #         @test foo(B) === B
    #     end

    #     # Triangular block matrices
    #     for foo in [adjoint, transpose]
    #         U = UpperTriangular(X)
    #         # @test foo(U) isa LowerTriangular{T, <:AbstractBlockMatrix{T}} where T
    #         @test Matrix(foo(U)) == foo(Matrix(U))

    #         L = LowerTriangular(X)
    #         # @test foo(L) isa UpperTriangular{T, <:AbstractBlockMatrix{T}} where T
    #         @test Matrix(foo(L)) == foo(Matrix(L))
    #     end
    # end

    # # Test multiplication of a `BlockMatrix` by a `BlockVector`.
    # let
    #     rng, P1, P2, Q1, Q2 = MersenneTwister(123456), 2, 3, 4, 5
    #     X11, X12 = randn(rng, P1, Q1), randn(rng, P1, Q2)
    #     X21, X22 = randn(rng, P2, Q1), randn(rng, P2, Q2)
    #     x1, x2 = randn(rng, Q1), randn(rng, Q2)
    #     A, x = BlockMatrix([X11, X21, X12, X22], 2, 2), BlockVector([x1, x2])

    #     @test length(A * x) == P1 + P2
    #     @test are_conformal(A, x)
    #     @test A * x isa AbstractBlockVector
    #     @test A * x ≈ Matrix(A) * Vector(x)

    #     x̂1, x̂2 = randn(rng, P1), randn(rng, P2)
    #     x̂ = BlockVector([x̂1, x̂2])

    #     @test are_conformal(A', x̂)
    #     @test A' * x̂ isa AbstractBlockVector
    #     @test Vector(A' * x̂) ≈ Matrix(A)' * Vector(x̂)

    #     @test are_conformal(transpose(A), x̂)
    #     @test transpose(A) * x̂ isa AbstractBlockVector
    #     @test Vector(transpose(A) * x̂) ≈ transpose(Matrix(A)) * Vector(x̂)

    #     @test_throws AssertionError A * Vector(x)
    #     @test_throws AssertionError transpose(A) * Vector(x̂)
    #     @test_throws AssertionError A' * Vector(x̂)
    # end

    # # Test multiplication of a `BlockMatrix` by a `BlockMatrix`.
    # let
    #     rng, P1, P2, Q1, Q2, R1, R2, R3 = MersenneTwister(123456), 2, 3, 4, 5, 6, 7, 8
    #     A11, A12 = randn(rng, P1, Q1), randn(rng, P1, Q2)
    #     A21, A22 = randn(rng, P2, Q1), randn(rng, P2, Q2)
    #     B11, B12, B13 = randn(rng, Q1, R1), randn(rng, Q1, R2), randn(rng, Q1, R3)
    #     B21, B22, B23 = randn(rng, Q2, R1), randn(rng, Q2, R2), randn(rng, Q2, R3)
    #     A = BlockMatrix([A11, A21, A12, A22], 2, 2)
    #     B = BlockMatrix([B11, B21, B12, B22, B13, B23], 2, 3)
    #     @test size(A * B, 1) == P1 + P2
    #     @test size(A * B, 2) == R1 + R2 + R3

    #     @test are_conformal(A, B)
    #     @test A * B isa AbstractBlockMatrix
    #     @test A * B ≈ Matrix(A) * Matrix(B)

    #     for foo in [adjoint, transpose]
    #         @test foo(B) * foo(A) isa AbstractBlockMatrix
    #         @test foo(B) * foo(A) ≈ foo(Matrix(B)) * foo(Matrix(A))

    #         @test foo(B) * B isa AbstractBlockMatrix
    #         @test foo(B) * B ≈ foo(Matrix(B)) * Matrix(B)

    #         @test B * foo(B) isa AbstractBlockMatrix
    #         @test B * foo(B) ≈ Matrix(B) * foo(Matrix(B))
    #     end
    # end

    # # Test `cholesky`, `logdet`, and backsolving.
    # let
    #     rng, P1, P2, P3 = MersenneTwister(123456), 3, 4, 5
    #     tmp = randn(rng, P1 + P2 + P3, P1 + P2 + P3)
    #     A_ = tmp * tmp' + 1e-9I
    #     A = BlockArray(A_, [P1, P2, P3], [P1, P2, P3])
    #     @assert A_ == A

    #     # Compute cholesky and compare.
    #     C_, C = cholesky(A_), cholesky(A)
    #     @test C isa Cholesky
    #     @test C_.U ≈ Matrix(C.U)
    #     @test C.U isa UpperTriangular{T, <:ABM{T}} where T

    #     # Test `logdet`.
    #     @test logdet(C) ≈ logdet(C_)

    #     # Check that the forwards-pass agrees.
    #     @test Zygote.forward(logdet, C)[1] == logdet(C)

    #     # Check that reverse-pass agrees with dense revese-pass.
    #     let
    #         ȳ = randn(rng)

    #         # Compute adjoint with dense.
    #         _, back_dense = Zygote.forward(logdet, C_)
    #         C̄_ = back_dense(ȳ)

    #         # Compute adjoint with block
    #         _, back_block = Zygote.forward(logdet, C)
    #         C̄ = back_block(ȳ)

    #         # Check that both answers approximately agree.
    #         @test C̄_[1].factors ≈ C̄[1].factors
    #     end

    #     # adjoint_test()

    #     # # Test backsolving for block vector.
    #     # x1, x2, x3 = randn(rng, P1), randn(rng, P2), randn(rng, P3)
    #     # x = BlockVector([x1, x2, x3])

    #     # @test U \ x isa AbstractBlockVector
    #     # @test size(U \ x) == size(U_ \ Vector(x))
    #     # @test U \ x ≈ U_ \ Vector(x)

    #     # @test U' \ x isa AbstractBlockVector
    #     # @test typeof(U') <: Adjoint{<:Real, <:UpperTriangular{<:Real, <:ABM}}
    #     # @test size(U' \ x) == size(U_' \ Vector(x))
    #     # @test U' \ x ≈ U_' \ Vector(x)

    #     # @test transpose(U) \ x isa AbstractBlockVector
    #     # @test typeof(transpose(U)) <: Transpose{<:Real, <:UpperTriangular{<:Real, <:ABM}}
    #     # @test size(transpose(U) \ x) == size(U_' \ Vector(x))
    #     # @test transpose(U) \ x ≈ U_' \ Vector(x)

    #     # # Test backsolving for block matrix
    #     # Q1, Q2 = 7, 6
    #     # X11, X12 = randn(rng, P1, Q1), randn(rng, P1, Q2)
    #     # X21, X22 = randn(rng, P2, Q1), randn(rng, P2, Q2)
    #     # X31, X32 = randn(rng, P3, Q1), randn(rng, P3, Q2)
    #     # X = BlockMatrix([X11, X21, X31, X12, X22, X32], 3, 2)

    #     # @test U \ X isa AbstractBlockMatrix
    #     # @test size(U \ X) == size(U_ \ Matrix(X))
    #     # @test U \ X ≈ U_ \ Matrix(X)

    #     # @test U' \ X isa AbstractBlockMatrix
    #     # @test size(U' \ X) == size(U_' \ Matrix(X))
    #     # @test U' \ X ≈ U_' \ Matrix(X)
    # end

    # # Test UniformScaling interaction.
    # let
    #     rng, N = MersenneTwister(123456), 5
    #     X = BlockArray(randn(rng, N, N), [2, 3], [2, 3])
    #     @test X + I isa AbstractBlockMatrix
    #     @test I + X isa AbstractBlockMatrix
    #     @test Matrix(X + I) == Matrix(X) + I
    #     @test Matrix(I + X) == I + Matrix(X)

    #     Xs = Symmetric(X)
    #     @test Xs + I isa Symmetric{T, <:AbstractBlockMatrix{T}} where T
    #     @test I + Xs isa Symmetric{T, <:AbstractBlockMatrix{T}} where T
    #     @test Matrix(Xs + I) == Matrix(Xs) + I
    #     @test Matrix(I + Xs) == I + Matrix(Xs)
    # end

    # # Run covariance matrix tests with a BlockMatrix.
    # let
    #     rng, P1, P2, Q1, Q2, R1, R2 = MersenneTwister(123456), 2, 3, 4, 5, 6, 7
    #     P, Q, R = P1 + P2, Q1 + Q2, R1 + R2
    #     B = randn(rng, P, P)
    #     A_ = BlockArray(B' * B + UniformScaling(1e-6), [P1, P2], [P1, P2])
    #     A = LazyPDMat(Symmetric(A_), 1e-12)
    #     x = BlockArray(randn(rng, P), [P1, P2])
    #     X = BlockArray(randn(rng, P, Q), [P1, P2], [Q1, Q2])
    #     X′ = BlockArray(randn(rng, P, R), [P1, P2], [R1, R2])

    #     # Check utility functionality.
    #     @test size(A) == size(A_)
    #     @test size(A, 1) == size(A_, 1)
    #     @test size(A, 2) == size(A_, 2)

    #     @test Matrix(A) == A_
    #     @test A == A

    #     # Test unary operations.
    #     @test logdet(A) ≈ logdet(Matrix(A_))
    #     @test chol(A) isa UpperTriangular{T, <:AbstractBlockMatrix{T}} where T
    #     @test chol(A) ≈ cholesky(Matrix(A_) + A.ϵ * I).U
 
    #     # Test binary operations.
    #     @test x + x isa AbstractBlockVector
    #     @test Vector(x + x) == Vector(x) + Vector(x)
    #     @test x - x isa AbstractBlockVector
    #     @test Vector(x - x) == Vector(x) - Vector(x)

    #     @test A_ + A_ isa AbstractBlockMatrix
    #     @test Matrix(A + A) == A_ + A_
    #     @test A_ - A_ isa AbstractBlockMatrix
    #     @test Matrix(A - A) == A_ - A_

    #     @test chol(A).data isa AbstractBlockMatrix
    #     @test x' * (Matrix(A_) \ x) ≈ Xt_invA_X(A, x)
    #     @test Xt_invA_X(A, X) isa LazyPDMat
    #     @test chol(Xt_invA_X(A, X)).data isa AbstractBlockMatrix
    #     @test maximum(abs.(Matrix(X') * (Matrix(A_) \ Matrix(X)) - Matrix(Xt_invA_X(A, X)))) < 1e-6
    #     @test Xt_invA_Y(X′, A, X) isa AbstractBlockMatrix
    #     @test maximum(abs.(Matrix(X′)' * (Matrix(A_) \ Matrix(X)) - Xt_invA_Y(X′, A, X))) < 1e-6
    #     @test A \ X isa AbstractBlockMatrix
    #     @test maximum(abs.(Matrix(A_) \ X - A \ X)) < 1e-6
    # end
end
