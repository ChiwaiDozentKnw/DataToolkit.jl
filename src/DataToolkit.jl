module DataToolkit

using Dates
using CSV
# using DataValues
using DataFrames
using Statistics
using Blink, TableView

export del_special_char, isnumber, notnumber, notdate, parse_m, allinteger, readCSV, unify_city_name, forceparse, forcedate, @get_namevalue_pairs, winsor!
export @replace!, @drop!, @by!, @filter, @filter!

# export @querying

export printdf

include("dataprocessing.jl")
include("visualization.jl")
include("statamacro.jl")

end