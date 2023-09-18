module TimeZonesExt
using Dates, TimeZones, Norg

@static if VERSION ≥ v"1.9"
    Norg.HAS_TIMEZONES_CAPABILITIES = true
end

function parse_timezone(::Val{:extension}, w)
    timezone = nothing
    try
        timezone = TimeZone(w)
    catch e
        if e isa ArgumentError
            @warn "Unable to process timezone" w
        else
            rethrow(e)
        end
    end
    return timezone
end
end
