module TimeZonesExt
using Dates, TimeZones, Norg

Norg.HAS_TIMEZONES_CAPABILITIES = true

function parse_timezone(::Val{:extension}, w)
    timezone = nothing
    try
        timezone = TimeZone(w)
    catch e
        if e isa ArgumentError
            @warn "Unable to process timezone" w tokens[i]
        else
            rethrow(e)
        end
    end
    timezone
end
