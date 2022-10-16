function parse_norg(::Type{T}, tokens, i,
                    parents) where {T <: AST.AttachedModifier}
    children = AST.Node[]
    opening_token = tokens[i]
    i = nextind(tokens, i)
    m = Match.MatchClosing{T}()
    while i <= lastindex(tokens)
        token = tokens[i]
        m = match_norg([T, parents...], tokens, i)
        @debug "attached modifier loop" T token m
        if isclosing(m)
            break
        end
        i, node = parse_norg(matched(m), tokens, i, [T, parents...])
        if node isa Vector{AST.Node}
            append!(children, node)
        elseif !isnothing(node)
            push!(children, node)
        end
    end
    if i > lastindex(tokens) || (isclosing(m) && matched(m) != T) # we've been tricked in thincking we were in a modifier.
        pushfirst!(children, AST.Node(AST.Word(value(opening_token))))
        i, children
    elseif isempty(children)
        i = nextind(tokens, i)
        i, nothing
    else
        i = nextind(tokens, i)
        i, AST.Node(children, T())
    end
end
