function del_special_char(str::String; exc = [])
    # TODO: Scientific notation and other tpyes of notations
    r = raw"\w|[\u4e00-\u9fa5]"
    for i in exc
        r = r * "|[$i]"
    end
    r = Regex("(" * r * ")")
    
    str = [i[1] for i in collect(eachmatch(r, str))]
    str = join(str)
    return replace(str, r"[_＿]"=>"")
end

function del_special_char(str::Missing; exc = [])
    return missing
end

function isnumber(str::AbstractString)
    try
        parse(Float64, str)
        return true
    catch e
        return false
    end
end

isnumber(str::Missing) = true

function notnumber(str::AbstractString)
    try
        parse(Float64, str)
        return false
    catch e
        return true
    end
end

notnumber(str::Missing) = false

function notdate(str::AbstractString; df=dateformat"y-m-d")
    try
        Date(str, df)
        return false
    catch e
        return true
    end
end

notdate(str::Missing) = false

parse_m(type, s) = parse(type, s)
parse_m(type, ::Missing) = missing

function allinteger(x)
    for i in x
        if !ismissing(isinteger(i))
            if isinteger(i) == false
                println(i)
                return false
            end
        end
    end
    return true
end

function readCSV(source; copycols::Bool=true, kwargs...)
    data = CSV.read(source; copycols=copycols, kwargs...)
    _names = names(data)
    _types = eltypes(data)
    for i in 1:length(_names)
        if String<:_types[i]
            data[ismissing.(data[_names[i]]), _names[i]] .= ""
        end
    end
    return data
end

function unify_city_name(s)
    if s === missing
        return missing
    elseif occursin(r"^阿拉尔", s)
        return "阿拉尔"
    elseif occursin(r"^阿拉善", s)
        return "阿拉善"
    elseif occursin(r"^张家口", s)
        return "张家口"
    elseif occursin(r"^张家界", s)
        return "张家界"
    else
        return s[1:4]
    end
end

function forceparse(type, x)
    try
        return parse(type, x)
    catch e
        if isa(e, ArgumentError)
            return missing
        else
            throw(e)
        end
    end
end

function forcedate(x)
    try
        return Date(x)
    catch e
        if isa(e, ArgumentError)
            return missing
        else
            throw(e)
        end
    end
end 

macro get_namevalue_pairs(args...)
    block = "Dict("
    for i in args
        block = block * "\"" * string(i) * "\"=>" * string(i) * ","
    end
    block = Meta.parse(block * ")")
    return esc(block)
end

function winsor!(data, var; by=[], cut=1:99)
    min = cut[1] / 100
    max = cut[end] / 100
    if by == []
        _lower_bound = quantile(data[var], min)
        _higher_bound = quantile(data[var], max)
        filter!(row->(row[var]>=_lower_bound && row[var]<=_higher_bound), data)
    else
        sort!(data, by)
        _groups = groupby(data, by, sort=true)
        _group_indexes = map(
            i->_groups.starts[i]:_groups.ends[i],
            1:length(_groups.starts)
        )
        valscat = DataFrames._combine(var=>x->quantile(x, max), _groups)[2][:, :value_function]
        values = collect(Iterators.flatten(map(
            i->fill(valscat[i], length(_group_indexes[i])), 
            1:length(valscat)
        )))
        data[!, :_higher_bound] = values

        valscat = DataFrames._combine(var=>x->quantile(x, min), _groups)[2][:, :value_function]
        values = collect(Iterators.flatten(map(
            i->fill(valscat[i], length(_group_indexes[i])), 
            1:length(valscat)
        )))
        data[!, :_lower_bound] = values

        filter!(row->(row[var]>=row[:_lower_bound] && row[var]<=row[:_higher_bound]), data)
        delete!(data, [:_higher_bound, :_lower_bound])
    end
    return data
end