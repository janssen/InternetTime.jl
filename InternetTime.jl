module InternetTime

TIMEZONE_OFFSETS = Dict("UT" => Dates.Hour(0),
                        "GMT" => Dates.Hour(0),
                        "EST" => Dates.Hour(-5),
                        "EDT" => Dates.Hour(-4),
                        "CST" => Dates.Hour(-6),
                        "CDT" => Dates.Hour(-5),
                        "MST" => Dates.Hour(-7),
                        "MDT" => Dates.Hour(-6),
                        "PST" => Dates.Hour(-8),
                        "PDT" => Dates.Hour(-7),
                        "Z" => Dates.Hour(0),
                        "A" => Dates.Hour(-1),
                        "M" => Dates.Hour(-12),
                        "N" => Dates.Hour(1),
                        "Y" => Dates.Hour(+12),
                        )

function __init__()
    # Base extension needs to happen everytime the module is loaded (issue #24)
    Dates.CONVERSION_SPECIFIERS['I'] = RFC822TimeZone
    Dates.CONVERSION_SPECIFIERS['i'] = RFC822TimeZone
    Dates.CONVERSION_DEFAULTS[RFC822TimeZone] = ""
    Dates.CONVERSION_TRANSLATIONS[RFC822DateTime] = (
        Year, Month, Day, Hour, Minute, Second, RFC822DateTime
    )

    global ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.ssszzz")
end

# No parsing of MIME type headers, so add a helper function or two
# Dates.RFC1123Format is invalid, as it doesn't account for timezone, so try to handle that.
function get_response_timestamp(headers)
    if haskey(headers, "Date")
        header_value = headers["Date"]
        timezone = nothing
        datetime = nothing
        while length(header_value) > 0 && datetime == nothing
            try
                datetime = DateTime(header_value, Dates.RFC1123Format)
                if timezone != nothing
                    # convert timezone to offset
                    if timezone in keys(TIMEZONE_OFFSETS)
                        offset = TIMEZONE_OFFSETS[timezone]
                        datetime = datetime + offset
                    elseif (m = match(r"^(\+|\-)([0-9]{2})([0-9]{2})$", timezone)) != nothing
                        hours = parse(Int64, m.captures[2])
                        minutes = parse(Int64, m.captures[3])
                        offset = Dates.Hour(hours) + Dates.Minute(minutes)
                        if m.captures[1] == "-"
                            datetime = datetime - offset
                        else
                            datetime = datetime + offset
                        end
                    else
                        println("unknown timezone: ", timezone)
                    end
                end
                return datetime
            catch x
                if isa(x, ArgumentError)
                    parts = split(header_value, " ")
                    if timezone == nothing && length(parts) > 1
                        timezone = parts[end]
                        header_value = join(parts[1:end-1], " ")
                    else
                        # only allowed 1 retry
                        rethrow()
                    end
                end
            end
        end
    end
    return nothing
end


end # module
