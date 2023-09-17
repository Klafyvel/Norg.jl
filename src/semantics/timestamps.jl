using Dates
"""
    parse_norg_timestamp(tokens, start, stop)

Parse a Norg timestamp to Julia DateTime. A timestamp has the following structure:

    <day>,? <day-of-month> <month> <year> <time> <timezone>

Refer to the Norg specification for further explanations.

Example usage:
    
    using Norg, AbstractTrees
    ast = norg"{@ Wed, 12th Jan - 20th Feb 2022}"
    node = first(collect(Leaves(ast)))
    Norg.parse_norg_timestamp(ast.tokens, node.start, node.stop)
"""
function parse_norg_timestamp(tokens, start, stop)
    i, t1 = parse_one_norg_timestamp(tokens, start, stop)
    if kind(tokens[i]) == K"-" || (i <= stop && kind(tokens[i+1]) == K"-")
        if kind(tokens[i]) != K"-"
            i += 1
        end
        i += 1
        if kind(tokens[i]) == K"Whitespace"
            i += 1
        end
        i, t2 = parse_one_norg_timestamp(tokens, i, stop)
        t1, t2 = complete_timestamps(t1, t2)
        t1, t2 = to_datetime(t1), to_datetime(t2)
        (;t1, t2)
    else
        (t1=to_datetime(t1), t2=nothing)
    end
    
end

function to_datetime(t)
    args = if isnothing(t.time)
        [t.year, t.month, t.day_of_month]
    else
        [t.year, t.month, t.day_of_month, hour(t.time), minute(t.time), second(t.time)]
    end
    stop = findfirst(isnothing.(args))
    if !isnothing(stop)
        args = args[1:stop-1]
    end
    if isempty(args)
        return nothing
    end    
    dt = DateTime(args...)
    if isnothing(t.timezone)
        dt
    else
        ZonedDateTime(dt, t.timezone)
    end
end

function complete_timestamps(t1, t2)
    complete_fields = [
        :day_of_month
        :month
        :year
        :time
    ]
    dt1 = Dict{Any,Any}(pairs(t1))
    dt2 = Dict{Any,Any}(pairs(t2))
    for field in complete_fields
        f1 = getfield(t1, field)
        f2 = getfield(t2, field)
        if isnothing(f1) && !isnothing(f2)
            dt1[field] = f2
        elseif !isnothing(f1) && isnothing(f2)
            dt2[field] = f1
        end
    end
    (t1=NamedTuple(dt1), t2=NamedTuple(dt2))
end

function warn_if_no_separator(param, tokens, i, stop)
    token = tokens[i]
    if kind(token) != K"Whitespace" && i <= stop
        @warn "$param not followed by space in timestamp" token
    end
end

function parse_one_norg_timestamp_should_return(tokens, i, stop)
    i >= stop || kind(tokens[i]) == K"-" || (i <= stop && kind(tokens[i+1]) == K"-")
end

function parse_one_norg_timestamp(tokens, start, stop)
    day = nothing
    day_of_month = nothing
    month = nothing
    year = nothing
    time = nothing
    timezone = nothing

    i = start
    token = tokens[i]
    w = value(token)
    if !any(isdigit.(collect(w)))
        day = parse_day(tokens, i, stop)
        i = nextind(tokens, i)
        token = tokens[i]
        if parse_one_norg_timestamp_should_return(tokens, i, stop)
            return i, (;day, day_of_month, month, year, time, timezone)
        elseif kind(token) == K","
            i = nextind(tokens, i)
            token = tokens[i]
        end
        if parse_one_norg_timestamp_should_return(tokens, i, stop)
            return i, (;day, day_of_month, month, year, time, timezone)
        else
            warn_if_no_separator("Day", tokens, i, stop)
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    w = value(token)
    m = match(r"^(?<day>\d{1,3})(?:st)?(?:nd)?(?:rd)?(?:th)?$", w)
    if !isnothing(m)
        day_of_month = parse(Int, m[:day])
        i = nextind(tokens, i)
        token = tokens[i]
        if parse_one_norg_timestamp_should_return(tokens, i, stop)
            return i, (;day, day_of_month, month, year, time, timezone)
        else
            warn_if_no_separator("Day of the month", tokens, i, stop)
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    w = value(token)
    if !any(isdigit.(collect(w)))
        month = parse_month(tokens, i, stop)
        i = nextind(tokens, i)
        token = tokens[i]
        if parse_one_norg_timestamp_should_return(tokens, i, stop)
            return i, (;day, day_of_month, month, year, time, timezone)
        else
            warn_if_no_separator("Month", tokens, i, stop)
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    w = value(token)
    if all(isdigit.(collect(w))) && length(token) >= 4
        year = parse_year(tokens, i, stop)
        i = nextind(tokens, i)
        token = tokens[i]
        if parse_one_norg_timestamp_should_return(tokens, i, stop)
            return i, (;day, day_of_month, month, year, time, timezone)
        else
            warn_if_no_separator("Year", tokens, i, stop)
            i = nextind(tokens, i)
            token = tokens[i]
        end
    end
    next_space = Parser.consume_until(KSet"Whitespace -", tokens, i) - 2
    if next_space <= stop
        s = join(value.(tokens[i:next_space]))
        time = tryparse(Time, s, dateformat"HH:MM.SS")
        if !isnothing(time)
            i = next_space+1
            if parse_one_norg_timestamp_should_return(tokens, i, stop)
                return i, (;day, day_of_month, month, year, time, timezone)
            else
                warn_if_no_separator("Time", tokens, i, stop)
                i = nextind(tokens, i)
                token = tokens[i]
            end
        end
    end
    if i <= stop
        stop_timestamp = Parser.consume_until(KSet"Whitespace -", tokens, i)-2
        if stop_timestamp <= stop
            w = join(value.(tokens[i:stop_timestamp]))
            timezone = parse_timezone(w)
            i = stop_timestamp + 1
        end
    end
    return i, (;day, day_of_month, month, year, time, timezone)
end

function parse_day(tokens, start, _)
    token = tokens[start]
    all_days = Dates.dayname.(1:7)
    w = value(token)
    candidates = findall(startswith.(all_days, Ref(w)))
    if length(candidates) > 1
        @warn "Ambiguous day in timestamp" token
        first(candidates)
    elseif length(candidates) == 0
        @warn "No day matching token" token
        nothing
    else
        first(candidates)
    end
end

function parse_day_of_month(tokens, start, _)
    token = tokens[start]
    w = value(token)
    dom = tryparse(Int, w)
    if isnothing(dom)
        @warn "Unable to parse day of the month in timestamp." token
        1
    else
        dom
    end
end

function parse_month(tokens, start, _)
    token = tokens[start]
    all_months = Dates.monthname.(1:12)
    w = value(token)
    candidates = findall(startswith.(all_months, Ref(w)))
    if length(candidates) > 1
        @warn "Ambiguous month in timestamp" token
        first(candidates)
    elseif length(candidates) == 0
        @warn "No month matching token" token
        nothing
    else
        first(candidates)
    end
end

function parse_year(tokens, start, _)
    token = tokens[start]
    w = value(token)
    tryparse(Int64, w)
end

function parse_timezone(w)
    if HAS_TIMEZONE_CAPABILITIES
        parse_timezone(Val(:extension), w)
    else
        nothing
    end
end

