#Query macro
#

macro replace!(data, replaceexp, ifexp)
    replaceexp_extended = extend_exp(:data_, replaceexp, "i")
    ifexp_extended = extend_exp(:data_, ifexp, "i")
    datalength = gensym("datalength")
    replacefunc = gensym("replacefunc")
    block = quote
        $datalength = size($(esc(data)), 1)
        function $replacefunc(data_, i)
            if $ifexp_extended
                $replaceexp_extended
            end
        end
        map(i->$replacefunc($(data), i), 1:$datalength)
        $(data)
    end
    return esc(block)
end

macro drop!(data, ifexp)
    # @drop! is not safe. Avoid using it.
    ifexp_extended = extend_exp(data, ifexp, "________i")
    rows_to_delete = gensym("rows_to_delete")
    datalength = gensym("datalength")
    return esc(
        quote
            $rows_to_delete = []
            $datalength = size($data, 1)
            for ________i in 1:$datalength
                if $ifexp_extended
                    push!($rows_to_delete, ________i)
                end
            end
            deleterows!($data, $rows_to_delete)
            $data
        end
    )
end

macro by!(data, keys, replace_exp)
    pair_splitted = split_replace_exp(replace_exp)
    _groups = gensym("_groups")
    _group_indexes = gensym("_group_indexes")
    f = gensym("f")
    p = gensym("p")
    valscat = gensym("valscat")
    values = gensym("values")
    # pair_extended = extend_pair_exp(:_current_data_part, replace_exp)
    block = quote
        sort!($data, $keys)
        $_groups = groupby($data, $keys, sort=true)
        # _groups = groupby($data, $keys).groups
        # _totalgroups = maximum(_groups)
        $_group_indexes = map(
            i->$_groups.starts[i]:$_groups.ends[i],
            1:length($_groups.starts)
        )
        for $p in $pair_splitted
            $f = eval(DataToolkit.pair_to_function($p))
            $valscat = DataFrames._combine(i->Base.invokelatest($f, i), $_groups)[2][:, :x1]
            $values = collect(Iterators.flatten(map(
                i->fill($valscat[i], length($_group_indexes[i])), 
                1:length($valscat)
            )))
            $(data)[!, eval($p[1])] = $values
        end
        $data 
        #= 
        for i in _totalgroups:-1:1
            start = findfirst(x->x==i, _groups)
            last = findlast(x->x==i, _groups)
            _current_data_part = $(data)[start:last, :]
            $pair_extended
            append!(_result, _current_data_part)
            deleterows!($data, start:last)
        end 
        =#
        
    end
    return esc(block)
end

macro filter!(data, ifexp)
    ifexp_extended = Meta.parse("row -> " * string(extend_filter_exp(ifexp)))
    block = quote
        filter!($ifexp_extended, $data)
    end
    return esc(block)
end

macro filter(data, ifexp)
    ifexp_extended = Meta.parse("row -> " * string(extend_filter_exp(ifexp)))
    block = quote
        filter($ifexp_extended, $data)
    end
    return esc(block)
end

function split_replace_exp(exp)
    if typeof(exp.args[1]) == QuoteNode
        result = [(exp.args[1], exp.args[2])]
        return Meta.parse("$result")
    elseif typeof(exp.args[1]) == Expr
        result = []
        for i in 1:length(exp.args[1].args)
            push!(result, (exp.args[1].args[i], exp.args[2].args[i]))
        end
        return Meta.parse("$result")
    end
end

function pair_to_function(pair)
    return extend_exp(:x, Meta.parse("x->$(pair[2])"), "!")
end    

function extend_exp(data, exp, ind)
    if isa(exp, Expr)
        head = Vector{Any}([exp.head])
        args = Vector{Any}(exp.args)
        for i in 1:size(args, 1)
            args[i] = extend_exp(data, args[i], ind)
        end
        return Expr(Tuple(append!(head, args))...)
    elseif isa(exp, QuoteNode)
        return Meta.parse(string(data) * "[$ind, " * string(exp) * "]")
    else
        return exp
    end
end

#=
function extend_pair_exp(data, exp)
    if isa(exp, Expr)
        if exp.head == :(=)
            exp.head = :(.=)
        end
        head = Vector{Any}([exp.head])
        args = Vector{Any}(exp.args)
        for i in 1:size(args, 1)
            args[i] = extend_pair_exp(data, args[i])
        end
        return Expr(Tuple(append!(head, args))...)
    elseif isa(exp, QuoteNode)
        return Meta.parse(string(data) * "[!, " * string(exp) * "]")
    else
        return exp
    end
end
=#

function extend_filter_exp(exp)
    if isa(exp, Expr)
        head = Vector{Any}([exp.head])
        args = Vector{Any}(exp.args)
        for i in 1:size(args, 1)
            args[i] = extend_filter_exp(args[i])
        end
        return Expr(Tuple(append!(head, args))...)
    elseif isa(exp, QuoteNode)
        return Meta.parse("row" * "[" * string(exp) * "]")
    else
        return exp
    end
end


#=
parse(type, x::DataValue{String}) = 
    if x == DataValue{String}()
        parse(type, missing)
    else
        parse(type, x.value)
    end

macro querying(exp)
    return colonToUnderscore(exp)
end

function colonToUnderscore(exp)
    if isa(exp, Expr)
        head = Vector{Any}([exp.head])
        args = Vector{Any}(exp.args)
        for i in 1:size(args, 1)
            args[i] = colonToUnderscore(args[i])
        end
        return Expr(Tuple(append!(head, args))...)
    elseif isa(exp, QuoteNode)
        return Meta.parse("_." * replace(string(exp), ":"=>""))
    elseif exp == :(:)
        return :_
    else
        return exp
    end
end
=#