"""
    consume_until(k, tokens, i)
    consume_until((k₁, k₂...), tokens, i)

Consume tokens until a token of kind `k` is encountered, or final token is reached.
"""
function consume_until(k::Kind, tokens::Vector{Token}, i)
    token = tokens[i]
    while !is_eof(token) && kind(token) != k
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) == k
        i = nextind(tokens, i)
    end
    return i
end
function consume_until(k, tokens::Vector{Token}, i)
    token = tokens[i]
    while !is_eof(token) && kind(token) ∉ k
        i = nextind(tokens, i)
        token = tokens[i]
    end
    if kind(token) ∈ k
        i = nextind(tokens, i)
    end
    return i
end

"""
    idify(text)

Make some text suitable for using it as an id in a document.
"""
function idify(text)
    words = map(lowercase, split(text, r"\W+"))
    return join(filter(!isempty, words), '-')
end

"""
    textify(ast, node, escape=identity)

Return the raw text associated with a node. You can specify an escape function.
"""
function textify(ast::NorgDocument, node::Node, escape=identity)
    if is_leaf(node)
        escape(AST.litteral(ast, node))
    else
        join(textify(ast, c, escape) for c in children(node))
    end
end

"""
    getchildren(node, k)
    getchildren(node, k[, exclude])

Return all children and grandchildren of kind `k`. It can also `exclude` 
certain nodes from recursion.
"""
function getchildren(node::Node, k::Kind)
    return filter(x -> kind(x) == k, collect(PreOrderDFS(x -> kind(x) != k, node)))
end
function getchildren(node::Node, k::Kind, exclude::Kind)
    return filter(
        x -> kind(x) == k,
        collect(PreOrderDFS(x -> kind(x) != k && kind(x) != exclude, node)),
    )
end
function getchildren(node::Node, k::Kind, exclude)
    return filter(
        x -> kind(x) == k,
        collect(PreOrderDFS(x -> kind(x) != k && kind(x) ∉ exclude, node)),
    )
end

"""
    findtargets!(ast[, node])

Iterate over the tree to (re)build the `targets` attribute of the AST, listing
all possible targets for magic links among direct children of `node`.

If `node` is not given, iterate over the whole AST, and `empty!` the `targets`
attribute of the AST first.
"""
function findtargets!(ast::NorgDocument)
    empty!(ast.targets)
    stack = copy(children(ast.root))
    while !isempty(stack)
        c = pop!(stack)
        findtargets!(ast, c)
        if kind(c) ∉ KSet"Link Anchor"
            append!(stack, children(c))
        end
    end
end
function findtargets!(ast::NorgDocument, node::Node)
    if AST.is_heading(node)
        push!(ast.targets, textify(ast, first(children(node))) => (kind(node), Ref(node)))
    elseif kind(node) ∈ KSet"Definition Footnote"
        for c in children(node)
            push!(ast.targets, textify(ast, first(children(c))) => (kind(node), Ref(c)))
        end
    end
end
