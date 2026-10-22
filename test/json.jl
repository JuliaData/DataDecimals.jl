# JSON 1.x integration tests. The main suite runs them with Parsers 3, and the
# test/json environment runs them with Parsers 2.
using Test, DataDecimals
using DataDecimals: DecimalValue
import JSON

struct JSONDecimalRecord
    price::Union{Nothing,Decimal{18,2,Int64}}
    qty::Union{Missing,DecimalValue{Int64}}
    history::Vector{Decimal{38,20,Int128}}
    byname::Dict{String,DecimalValue{Int64}}
end

@testset "JSON exact numbers" begin
    wide = Decimal{38,20,Int128}("12345678901234567.89012345678901234567")
    @test JSON.json(Dict("v" => wide)) ==
          "{\"v\":12345678901234567.89012345678901234567}"
    @test JSON.json([Decimal{18,2}("1.25"), DecimalValue{Int64}(5, 3)]) ==
          "[1.25,0.005]"
    # round-trips through JSON.parse as a number
    @test JSON.parse(JSON.json(Dict("v" => Decimal{18,2}("1.25"))))["v"] == 1.25
end

@testset "JSON reads decimals from their digits" begin
    D2 = Decimal{18,2,Int64}
    D20 = Decimal{38,20,Int128}
    DV = DecimalValue{Int64}
    wide = D20("123456789012345678.12345678901234567891")
    # every digit survives a round trip (Float64 kept about 17)
    @test JSON.parse(JSON.json(wide), D20) == wide
    @test JSON.parse(JSON.json([wide]), Vector{D20}) == [wide]
    # rounding to the scale happens once, from the text, as in the string constructor
    @test JSON.parse("12.345", D2) == D2("12.345") == D2("12.34")
    @test JSON.parse("0.125", D2) == D2("0.12")
    @test JSON.parse("1.5e2", D2) == D2("150")
    # a DecimalValue keeps the number's scale
    @test string(JSON.parse("12.30", DV)) == "12.30"
    @test string(JSON.parse("-0.0", DV)) == "0.0"
    @test string(JSON.parse(JSON.json(DV("12.500")), DV)) == "12.500"
    # a value that does not fit throws instead of rounding through Float64
    @test_throws OverflowError JSON.parse("99999999999999999.99", DV)
    @test_throws OverflowError JSON.parse("123456789012345678", D2)
    @test_throws OverflowError JSON.parse("1e400", D2)
    # nested targets
    rec = JSON.parse("""{"price":19.99,"qty":0.250,"history":[$(JSON.json(wide))],"byname":{"a":10.10}}""",
        JSONDecimalRecord)
    @test rec.price == D2("19.99")
    @test string(rec.qty) == "0.250"
    @test rec.history == [wide]
    @test string(rec.byname["a"]) == "10.10"
    rec = JSON.parse("""{"price":null,"qty":null,"history":[],"byname":{}}""", JSONDecimalRecord)
    @test rec.price === nothing && rec.qty === missing
    @test JSON.parse(JSON.lazy("12.34"), D2) == D2("12.34")
    @test JSON.parse("1.25", Decimal{18,2}) === D2("1.25")
    @test JSON.parse("+1.5", D2; allownan=true) == D2("1.5")
    # other JSON values keep their existing errors
    @test_throws InexactError JSON.parse("NaN", D2; allownan=true)
    @test_throws MethodError JSON.parse("\"1.5\"", D2)
    if isdefined(JSON, :ParseError)  # JSON 1.11
        err = try
            JSON.parse("""{"history":[1, 1e400]}""", @NamedTuple{history::Vector{D2}}; error_context=true)
        catch e
            e
        end
        @test err isa JSON.ParseError && err.path == "/history/1" && err.cause isa OverflowError
    end
    # untyped and Float64 targets are unchanged
    @test JSON.parse("12.345") === 12.345
    @test JSON.parse("12.345", Float64) === 12.345
end
