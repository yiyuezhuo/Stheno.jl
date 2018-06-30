import Distances: pairwise

"""
    DeltaSumMean{Tϕ, Tg, TZ} <: MeanFunction

"""
struct DeltaSumMean{Tϕ, Tg} <: MeanFunction
    ϕ::Tϕ
    μ::MeanFunction
    g::Tg
end
(μ::DeltaSumMean)(x::Number) = _map(μ, [x])[1]
(μ::DeltaSumMean)(X::AV) = _map(μ, MatData(reshape(X, :, 1)))[1]
function _map(μ::DeltaSumMean, X::AV)
    Z = eachindex(μ.ϕ, 1)
    @show Z
    return pairwise(μ.ϕ, Z, X)' * map(μ.μ, Z) + map(μ.g, X)
end
eachindex(μ::DeltaSumMean) = eachindex(g)

"""
    DeltaSumKernel{Tϕ, TZ} <: Kernel

"""
struct DeltaSumKernel{Tϕ, TZ} <: Kernel
    ϕ::Tϕ
    k::Kernel
    Z::TZ
end
(k::DeltaSumKernel)(x::Number, x′::Number) = map(k, [x], [x′])[1]
function (k::DeltaSumKernel)(x::AV, x′::AV)
    return map(k, MatData(reshape(x, :, 1)), MatData(reshape(x′, :, 1)))[1]
end
size(k::DeltaSumKernel, N::Int) = size(k.ϕ, 2)

function _map(k::DeltaSumKernel, X::AV)
    return diag_Xᵀ_A_X(pairwise(k.k, k.Z), pairwise(k.ϕ, k.Z, X))
end
function _map(k::DeltaSumKernel, X::AV, X′::AV)
    return diag_Xᵀ_A_Y(pairwise(k.ϕ, k.Z, X), pairwise(k.k, k.Z), pairwise(k.ϕ, k.Z, X′))
end
function _pairwise(k::DeltaSumKernel, X::AV)
    return Xt_A_X(pairwise(k.k, k.Z), pairwise(k.ϕ, k.Z, X))
end
function _pairwise(k::DeltaSumKernel, X::AV, X′::AV)
    return Xt_A_Y(pairwise(k.ϕ, k.Z, X), pairwise(k.k, k.Z), pairwise(k.ϕ, k.Z, X′))
end

"""

"""
struct LhsDeltaSumCrossKernel{Tϕ, TZ} <: CrossKernel
    ϕ::Tϕ
    k::CrossKernel
    Z::TZ
end
(k::LhsDeltaSumCrossKernel)(x::Number, x′::Number) = map(k, [x], [x′])[1]
function (k::LhsDeltaSumCrossKernel)(x::AV, x′::AV)
    return map(k, MatData(reshape(x, : ,1)), MatData(reshape(x′, :, 1)))[1]
end
size(k::LhsDeltaSumCrossKernel, N::Int) = N == 1 ? size(k.ϕ, 2) : size(k.k, 2)

function _map(k::LhsDeltaSumCrossKernel, X::AV, X′::AV)
    return diag_AᵀB(pairwise(k.ϕ, k.Z, X), pairwise(k.k, k.Z, X′))
end
function _pairwise(k::LhsDeltaSumCrossKernel, X::AV, X′::AV)
    return pairwise(k.ϕ, k.Z, X)' * pairwise(k.k, k.Z, X′)
end

"""

"""
struct RhsDeltaSumCrossKernel{TZ, Tϕ} <: CrossKernel
    k::CrossKernel
    Z::TZ
    ϕ::Tϕ
end
(k::RhsDeltaSumCrossKernel)(x::Number, x′::Number) = map(k, [x], [x′])[1]
function (k::RhsDeltaSumCrossKernel)(x::AV, x′::AV)
    return map(k, MatData(reshape(x, :, 1)), MatData(reshape(x′, :, 1)))[1]
end
size(k::RhsDeltaSumCrossKernel, N::Int) = N == 1 ? size(k.k, 2) : size(k.ϕ, 2)

@noinline function _map(k::RhsDeltaSumCrossKernel, X::AV, X′::AV)
    return diag_AᵀB(pairwise(k.k, k.Z, X), pairwise(k.ϕ, k.Z, X′))
end
function _pairwise(k::RhsDeltaSumCrossKernel, X::AV, X′::AV)
    return pairwise(k.k, k.Z, X)' * pairwise(k.ϕ, k.Z, X′)
end


# """
#     DegenerateKernel <: Kernel

# A rank-limited kernel, for which `k(x, x′) = kfg(:, x)' * A * kfg(:, x′)`.

# # Fields
# - `A<:LazyPDMat`:
# - `kfg<:CrossKernel`:
# """
# struct DegenerateKernel{TA<:LazyPDMat} <: Kernel
#     A::TA
#     kfg::CrossKernel
#     function DegenerateKernel(A::TA, kfg::CrossKernel) where TA<:LazyPDMat
#         @assert isfinite(size(kfg, 1)) && size(kfg, 1) == size(A, 1)
#         @assert size(A, 1) == size(A, 2)
#         return new{TA}(A, kfg)
#     end
# end
# (k::DegenerateKernel)(x::Number, x′::Number) = map(k, [x], [x′])[1]
# (k::DegenerateKernel)(x::AV, x′::AV) =
#     map(k, reshape(x, length(x), 1), reshape(x′, length(x′), 1))[1]
# size(k::DegenerateKernel, N::Int) = size(k.k, 2)

# map(k::DegenerateKernel, X::AVM) = diag_Xᵀ_A_X(k.A, pairwise(k.kfg, :, X))
# function map(k::DegenerateKernel, X::AVM, X′::AVM)
#     return diag_Xᵀ_A_Y(pairwise(k.kfg, :, X), k.A, pairwise(k.kfg, :, X′))
# end
# pairwise(k::DegenerateKernel, X::AVM) = Xt_A_X(k.A, pairwise(k.kfg, :, X))
# function pairwise(k::DegenerateKernel, X::AVM, X′::AVM)
#     return Xt_A_Y(pairwise(k.kfg, :, X), k.A, pairwise(k.kfg, :, X′))
# end

# """
#     DegenerateCrossKernel <: CrossKernel

# Rank-limited cross-kernel, for which `k(x, x′) = kfg(:, x)' * A * kfh(:, x′)`.
# """
# struct DegenerateCrossKernel{TA<:AbstractMatrix} <: CrossKernel
#     kfg::CrossKernel
#     A::TA
#     kfh::CrossKernel
#     function DegenerateCrossKernel(kfg::CrossKernel, A::TA, kfh::CrossKernel) where TA<:AM
#         @assert isfinite(size(kfg, 1)) && size(kfg, 1) == size(A, 1)
#         @assert isfinite(size(kfh, 1)) && size(kfh, 1) == size(A, 2)
#         return new{TA}(kfg, A, kfh)
#     end
# end
# (k::DegenerateCrossKernel)(x::Number, x′::Number) = map(k, [x], [x′])[1]
# (k::DegenerateCrossKernel)(x::AV, x′::AV) =
#     map(k, reshape(x, length(x), 1), reshape(x′, length(x′), 1))[1]
# function size(k::DegenerateCrossKernel, N::Int)
#     @assert N ∈ (1, 2)
#     return N == 1 ? size(k.kfg, 2) : size(k.kfh, 2)
# end

# function map(k::DegenerateCrossKernel, X::AVM, X′::AVM)
#     return diag_Xᵀ_A_Y(pairwise(k.kfg, :, X), k.A, pairwise(k.kfh, :, X′))
# end
# function binary_pairwise(k::DegenerateCrossKernel, X::AVM, X′::AVM)
#     return Xt_A_Y(pairwise(k.kfg, :, X), k.A, pairwise(k.kfh, :, X′))
# end
