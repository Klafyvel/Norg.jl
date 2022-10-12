function match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Colon}, parents,
                    tokens, i)
    MatchFound{AST.FileLocation}()
end
function match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.NumberSign},
                    parents, tokens, i)
    MatchFound{AST.MagicLocation}()
end
function match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Slash}, parents,
                    tokens, i)
    MatchFound{AST.FileLinkableLocation}()
end
# TODO: This works since headings are the only form of structural detached
# modifiers AND in layer two range-able detached modifiers do not exist.
function match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Star}, parents,
                    tokens, i)
    MatchFound{AST.DetachedModifierLocation}()
end

function match_norg(::Type{AST.LinkLocation}, token::Token{<:Tokens.TokenType},
                    parents, tokens, i)
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchFound{AST.URLLocation}()
    end
end

function match_norg(::Type{AST.LinkDescription},
                    ::Token{Tokens.LeftSquareBracket}, parents, tokens, i)
    MatchFound{AST.LinkDescription}()
end
function match_norg(t::Type{AST.LinkDescription}, token, parents, tokens, i)
    match_norg(first(parents), t, token, parents, tokens, i)
end
function match_norg(t::Type{AST.Link}, ::Type{AST.LinkDescription}, token,
                    parents, tokens, i)
    MatchClosing{t}()
end
function match_norg(::Type{<:AST.NodeData}, ::Type{AST.LinkDescription}, token,
                    parents, tokens, i)
    MatchNotFound()
end
function match_norg(::Type{AST.FileLinkableLocation},
                    ::Type{AST.LinkDescription}, token, parents, tokens, i)
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchNotFound()
    end
end
function match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription},
                    ::Token{Tokens.Star}, parents, tokens, i)
    MatchFound{AST.DetachedModifierLocation}()
end
function match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription},
                    ::Token{Tokens.NumberSign}, parents, tokens, i)
    MatchFound{AST.MagicLocation}()
end
function match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription},
                    token, parents, tokens, i)
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchNotFound()
    end
end

function match_norg(::Type{AST.Anchor}, ::Token{Tokens.LeftSquareBracket},
                    parents, tokens, i)
    MatchFound{AST.Anchor}()
end
match_norg(::Type{AST.Anchor}, token, parents, tokens, i) = MatchNotFound()
