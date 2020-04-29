module DataToolkit

import Base: parse, replace
using Dates
using CSV
# using DataValues
using DataFrames
using Blink, TableView

export replace2, parse2, isnumber, allinteger, forceparse, forcedate, @replace!, @drop!, @by!, @filter, @filter!

# export @querying

export printdf

include("dataprocessing.jl")
include("visualization.jl")
include("statamacro.jl")

end