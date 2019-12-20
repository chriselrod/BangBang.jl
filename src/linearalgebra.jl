"""
    add!!(A, B) -> A′

`A .+= B` if possible; otherwise return `A .+ B`.

# Examples
```jldoctest
julia> using BangBang: add!!

julia> add!!((1,), (2,))
(3,)

julia> add!!([1], [2])
1-element Array{Int64,1}:
 3
```
"""
add!!(A, B) = may(add!, A, B)
add!(A, B) = A .+= B

pure(::typeof(add!)) = NoBang.add
_asbb(::typeof(add!)) = add!!
possible(::typeof(add!), A, B) = ismutable(A) && _addeltype(A, B) <: eltype(A)

_addeltype(A, B) = Base.promote_op(+, eltype(A), _eltype(B))
_eltype(x) = eltype(x)
function _eltype(x::Broadcast.Broadcasted)
    bc = Broadcast.instantiate(x)
    return Base._return_type(getindex, Tuple{typeof(bc), Vararg{Int, ndims(bc)}})
end
# TODO: Implement `materialize!!(dest, bc)` based on `copyto_nonleaf!`
# and use it like this:
# add!!(A, B) = materialize!!(A, instantiate(broadcasted(+, A, B)))

"""
    mul!!(C, A, B, [α, β]) -> C′
"""
mul!!(C, A, B) = may(mul!, C, A, B)
mul!!(C, A, B, α, β) = may(mul!, C, A, B, α, β)

pure(::typeof(mul!)) = NoBang.mul
_asbb(::typeof(mul!)) = mul!!
possible(::typeof(mul!), C, A, B) =
    ismutable(C) && _matmuleltype(A, B) <: eltype(C)
possible(::typeof(mul!), C, A, B, α, β) =
    ismutable(C) && _matmuleltype(C, A, B, α, β) <: eltype(C)

# Estimate `eltype` of `C`.  This is how it's done in LinearAlgebra.jl
# but maybe it's better to use the approach of
# https://github.com/tpapp/AlgebraResultTypes.jl ?
_matprod(x, y) = x * y + x * y
_matprod(c, a, b, α, β) = a * b * α + a * b * α + c * β
_matmuleltype(A, B) = Base.promote_op(_matprod, eltype(A), eltype(B))
_matmuleltype(C, A, B, α, β) =
    Base.promote_op(_matprod, eltype(C), eltype(A), eltype(B), typeof(α), typeof(β))

"""
    lmul!!(A, B) -> B′
"""
lmul!!(A, B) = may(lmul!, A, B)

pure(::typeof(lmul!)) = *
_asbb(::typeof(lmul!)) = lmul!!
possible(::typeof(lmul!), A, B) =
    ismutable(B) && _matmuleltype(A, B) <: eltype(B)

"""
    rmul!!(A, B) -> A′
"""
rmul!!(A, B) = may(rmul!, A, B)

pure(::typeof(rmul!)) = *
_asbb(::typeof(rmul!)) = rmul!!
possible(::typeof(rmul!), A, B) =
    ismutable(A) && _matmuleltype(A, B) <: eltype(A)
