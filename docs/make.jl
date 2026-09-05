using Documenter
using DataDecimals

DocMeta.setdocmeta!(DataDecimals, :DocTestSetup, :(using DataDecimals); recursive=true)

makedocs(;
    modules=[DataDecimals],
    sitename="DataDecimals.jl",
    authors="Jacob Quinn and contributors",
    # set explicitly so the build works from a checkout without an origin remote
    repo=Documenter.Remotes.GitHub("JuliaData", "DataDecimals.jl"),
    format=Documenter.HTML(;
        canonical="https://JuliaData.github.io/DataDecimals.jl/stable/",
        prettyurls=true,
        edit_link="main",
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => "manual.md",
        "Semantics" => "semantics.md",
        "Migration from Decimals.jl" => "migration.md",
        "API Reference" => "api.md",
    ],
    doctest=true,
)

deploydocs(;
    repo="github.com/JuliaData/DataDecimals.jl.git",
    devbranch="main",
    push_preview=true,
)
