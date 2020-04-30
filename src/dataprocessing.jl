function del_special_char(str::String; exc = [])
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

function isnumber(str)
    if typeof(forceparse(Float64, str)) == Float64
        return true
    else
        return false
    end
end

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