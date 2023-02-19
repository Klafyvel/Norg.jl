function parse_norg(::DetachedModifierExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    m = match_norg(DetachedModifierExtension(), parents, tokens, i)
    if !Match.isfound(m)
        return AST.Node(K"None")        
    end
    extension = matched(m)
    if extension == K"TodoExtension"
        parse_norg(TodoExtension(), parents, tokens, i)
    elseif extension == K"TimestampExtension"
        parse_norg(TimestampExtension(), parents, tokens, i)
    elseif extension == K"PriorityExtension"
        parse_norg(PriorityExtension(), parents, tokens, i)
    elseif extension == K"DueDateExtension"
        parse_norg(DueDateExtension(), parents, tokens, i)
    elseif extension == K"StartDateExtension"
        parse_norg(StartDateExtension(), parents, tokens, i)
    else
        error("Unhandled detached modifier extension. Token $token.")
    end
end
function parse_norg(::TodoExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    token = tokens[i]
    statusstart=i
    if kind(token) == K"Whitespace"
        status = K"StatusUndone"
    elseif kind(token) == K"x"
        status = K"StatusDone"
    elseif kind(token) == K"?"
        status = K"StatusNeedFurtherInput"
    elseif kind(token) == K"!"
        status = K"StatusUrgent"
    elseif kind(token) == K"+"
        status = K"StatusRecurring"
    elseif kind(token) == K"-"
        status = K"StatusInProgress"
    elseif kind(token) == K"="
        status = K"StatusOnHold"
    elseif kind(token) == K"_"
        status = K"StatusCancelled"
    else
        error()
    end
    i = nextind(tokens, i)
    token = tokens[i]
    piped = AST.Node(K"None")
    if kind(token) == K"|"
        piped = parse_norg(DetachedModifierExtension(), parents, tokens, i)
        i = piped.stop
    end
    if kind(piped) == K"None"
        AST.Node(K"TodoExtension", [AST.Node(status, [], statusstart, statusstart)], start, i)
    else
        AST.Node(K"TodoExtension", [AST.Node(status, [], statusstart, statusstart), piped], start, i)
    end
end

function parse_norg(::TimestampExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    starttimestamp = i
    token = tokens[i]
    while kind(token) ∉ KSet"| ) EndOfFile"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    piped = AST.Node(K"None")
    stoptimestamp = i
    timestamp = AST.Node(K"Timestamp", [], starttimestamp, stoptimestamp)
    if kind(token) == K"|"
        piped = parse_norg(DetachedModifierExtension(), parents, tokens, i)
        i = piped.stop
    end
    if kind(piped) == K"None"
        AST.Node(K"TimestampExtension", [timestamp], start, i)
    else
        AST.Node(K"TimestampExtension", [timestamp, piped], start, i)
    end
end

function parse_norg(::PriorityExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    startpriority = i
    token = tokens[i]
    while kind(token) ∉ KSet"| ) EndOfFile"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    piped = AST.Node(K"None")
    stoppriority = i
    priority = AST.Node(K"Word", [], startpriority, stoppriority)
    if kind(token) == K"|"
        piped = parse_norg(DetachedModifierExtension(), parents, tokens, i)
        i = piped.stop
    end
    if kind(piped) == K"None"
        AST.Node(K"PriorityExtension", [priority], start, i)
    else
        AST.Node(K"PriorityExtension", [priority, piped], start, i)
    end
end

function parse_norg(::DueDateExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    starttimestamp = i
    token = tokens[i]
    while kind(token) ∉ KSet"| ) EndOfFile"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    piped = AST.Node(K"None")
    stoptimestamp = i
    timestamp = AST.Node(K"Timestamp", [], starttimestamp, stoptimestamp)
    if kind(token) == K"|"
        piped = parse_norg(DetachedModifierExtension(), parents, tokens, i)
        i = piped.stop
    end
    if kind(piped) == K"None"
        AST.Node(K"DueDateExtension", [timestamp], start, i)
    else
        AST.Node(K"DueDateExtension", [timestamp, piped], start, i)
    end
end

function parse_norg(::StartDateExtension, parents::Vector{Kind}, tokens::Vector{Token}, i)
    start = i
    i = nextind(tokens, i)
    starttimestamp = i
    token = tokens[i]
    while kind(token) ∉ KSet"| ) EndOfFile"
        i = nextind(tokens, i)
        token = tokens[i]
    end
    piped = AST.Node(K"None")
    stoptimestamp = i
    timestamp = AST.Node(K"Timestamp", [], starttimestamp, stoptimestamp)
    if kind(token) == K"|"
        piped = parse_norg(DetachedModifierExtension(), parents, tokens, i)
        i = piped.stop
    end
    if kind(piped) == K"None"
        AST.Node(K"StartDateExtension", [timestamp], start, i)
    else
        AST.Node(K"StartDateExtension", [timestamp, piped], start, i)
    end
end
