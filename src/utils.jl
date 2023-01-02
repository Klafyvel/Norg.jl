"""
    consume_until(k, tokens, i)
    consume_until((k₁, k₂...), tokens, i)

Consume tokens until a token of kind `k` is encountered, or final token is reached.
"""
function consume_until(k::Kind, tokens, i)
    token = tokens[i]
    while !is_eof(token) && kind(token) != k
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) == k
        i = nextind(tokens, i)
    end
    i
end
function consume_until(k, tokens, i)
    token = tokens[i]
    while !is_eof(token) && kind(token) ∉ k
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) ∈ k
        i = nextind(tokens, i)
    end
    i
end


