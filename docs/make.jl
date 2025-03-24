using WflowRaster
using Documenter

DocMeta.setdocmeta!(WflowRaster, :DocTestSetup, :(using WflowRaster); recursive = true)

const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
    file != "index.md" && splitext(file)[2] == ".md"
]

makedocs(;
    modules = [WflowRaster],
    authors = "Joseph A.P. Pollacco,",
    repo = "https://github.com/AquaPore/WflowRaster.jl/blob/{commit}{path}#{line}",
    sitename = "WflowRaster.jl",
    format = Documenter.HTML(; canonical = "https://AquaPore.github.io/WflowRaster.jl"),
    pages = ["index.md"; numbered_pages],
)

deploydocs(; repo = "github.com/AquaPore/WflowRaster.jl")
