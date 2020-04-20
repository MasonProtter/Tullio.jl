module Tullio

#========== ⚜️ ==========#

export @tullio

@nospecialize

include("tools.jl")

include("macro.jl")

include("symbolic.jl")

include("forward.jl")

include("einsum.jl")

@specialize

include("shifts.jl")

include("threads.jl")


#========== ⚜️ ==========#

"""
    storage_type(adjoint(view(A,...))) == Array{Int,2}
    storage_type(A, B, C) == Array{Int,N} where N

Recursively unwraps wrappers, and combines with `promote_type`.
(Used as the trait to send CuArray to KernelAbstractions
and Array{Float or Int} to LoopVectorization.)
"""
function storage_type(A::AbstractArray)
    P = parent(A)
    typeof(A) === typeof(P) ? typeof(A) : storage_type(P)
end
storage_type(A) = typeof(A)
storage_type(A, Bs...) = Base.promote_type(storage_type(A), storage_type(Bs...))
storage_type() = AbstractArray

storage_typejoin(A, Bs...) = Base.promote_typejoin(storage_type(A), storage_typejoin(Bs...))
storage_typejoin(A) = storage_type(A)

#========== ⚜️ ==========#

using Requires

function __init__()
    @require LoopVectorization = "bdcacae8-1622-11e9-2a5c-532679323890" begin

        # some missing definitions, should live SLEEFpirates?
        using .LoopVectorization: SVec
        @inline svec(tup::NTuple{N,T}) where {N,T} = SVec{N,T}(tup...)
        @inline Base.inv(sv::SVec{N,<:Integer}) where {N} = svec(ntuple(n -> inv(sv[n]), N))
        @inline Base.sqrt(sv::SVec{N,<:Integer}) where {N} = svec(ntuple(n -> sqrt(sv[n]), N))
        @inline Base.trunc(T::Type, sv::SVec{N}) where {N} = svec(ntuple(n -> trunc(T, sv[n]), N))

        @require ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210" begin
            # dual numbers + svec, should live in PaddedMatricesForwardDiff?
            # (And where would the conditional loading go, still here?)
            include("avxdual.jl")
        end

    end
end

#========== ⚜️ ==========#

end # module
