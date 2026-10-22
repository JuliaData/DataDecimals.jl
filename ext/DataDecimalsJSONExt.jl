# Write decimals as JSON numbers carrying their exact digits, through the JSON
# 1.x hook for it; the default for an unknown Real stringifies convert(Float64,
# x) and would round wide values away. The positional print form is always a
# valid JSON number, since a decimal is always finite.
#
# Read a JSON number into a decimal from its digits. JSON's default number path
# converts through Float64: it keeps 15-17 significant digits, rounds a second
# time to the decimal's scale, and cannot represent a DecimalValue with a
# fractional part.
module DataDecimalsJSONExt

using DataDecimals
using DataDecimals: AbstractDecimal, Decimal, DecimalValue
import JSON

JSON.tostring(x::AbstractDecimal) = string(x)

# The reading method uses JSON's number scanner, which has this shape from JSON 1.8.
@static if isdefined(JSON, :exactintegerend)

using JSON: Parsers, StructUtils, JSONReadStyle, LazyValues, JSONTypes

function StructUtils.lift(style::JSONReadStyle, ::Type{T}, x::LazyValues, tags=(;)) where {T<:Union{Decimal,DecimalValue}}
    JSON.gettype(x) == JSONTypes.NUMBER || return _jsonlift(style, T, x, tags)
    buf = JSON.getbuf(x)
    pos = JSON.getpos(x)
    len = JSON.getlength(buf)
    nextpos, isfloat, _, _ = JSON.scannumber(buf, pos, len)
    # invalid tokens and `allownan` spellings keep JSON's path and its errors
    nextpos == pos && return _jsonlift(style, T, x, tags)
    stop = isfloat ? JSON.exactintegerend(buf, pos, nextpos, len) : nextpos
    return _parsejson(T, JSON.numberbytes(buf), pos, stop - 1), stop
end

_jsonlift(style, ::Type{T}, x, tags) where {T} =
    @invoke StructUtils.lift(style::JSONReadStyle, T::Type, x::LazyValues, tags::Any)

# Both conversions round half-even to a Decimal's scale, keep a DecimalValue's
# scale, and throw OverflowError when the value does not fit.
@static if isdefined(JSON.Parsers, :xparse2)
    # Parsers 2 has no decimal parser. Copy the slice: copying a `view` of a
    # String's code units costs O(length of the whole String).
    _parsejson(::Type{T}, bytes, first, last) where {T} = T(String(bytes[first:last]))
else
    # Parsers 3: the Parsers extension parses the span in place.
    _parsejson(::Type{T}, bytes, first, last) where {T} = Parsers.parse(T, bytes, first, last)
end

end # @static if

end # module
