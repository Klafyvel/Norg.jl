match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Colon}, parents, tokens, i) = MatchFound{AST.FileLocation}()
match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.NumberSign}, parents, tokens, i) = MatchFound{AST.MagicLocation}()
match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Slash}, parents, tokens, i) = MatchFound{AST.FileLinkableLocation}()
# TODO: This works since headings are the only form of structural detached
# modifiers AND in layer two range-able detached modifiers do not exist.
match_norg(::Type{AST.LinkLocation}, ::Token{Tokens.Star}, parents, tokens, i) = MatchFound{AST.DetachedModifierLocation}()

function match_norg(::Type{AST.LinkLocation}, token::Token{<:Tokens.TokenType}, parents, tokens, i)
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchFound{AST.URLLocation}()
    end
end

match_norg(::Type{AST.LinkDescription}, ::Token{Tokens.LeftSquareBracket}, parents, tokens, i) = MatchFound{AST.LinkDescription}()
match_norg(t::Type{AST.LinkDescription}, token, parents, tokens, i) = match_norg(first(parents), t, token, parents, tokens, i)
match_norg(t::Type{AST.Link}, ::Type{AST.LinkDescription}, token, parents, tokens, i) = MatchClosing{t}()
match_norg(::Type{<:AST.NodeData}, ::Type{AST.LinkDescription}, token, parents, tokens, i) = MatchNotFound()
function match_norg(::Type{AST.FileLinkableLocation}, ::Type{AST.LinkDescription}, token, parents, tokens, i)
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchNotFound()
    end
end
match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription}, ::Token{Tokens.Star}, parents, tokens, i) = MatchFound{AST.DetachedModifierLocation}()
match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription}, ::Token{Tokens.NumberSign}, parents, tokens, i) = MatchFound{AST.MagicLocation}()
function match_norg(::Type{AST.FileLocation}, ::Type{AST.LinkDescription}, token, parents, tokens, i) 
    if isnumeric(first(value(token)))
        MatchFound{AST.LineNumberLocation}()
    else
        MatchNotFound()
    end
end

match_norg(::Type{AST.Anchor}, ::Token{Tokens.LeftSquareBracket}, parents, tokens, i) = MatchFound{AST.Anchor}()
match_norg(::Type{AST.Anchor}, token, parents, tokens, i) = MatchNotFound()
