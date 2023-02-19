"""
Norg.jl provides a way to parse [Neorg](https://github.com/nvim-neorg/neorg)
files in pure Julia.

It overloads `Base.parse` with custom targets. So far the only available target
is `HTMLTarget`.

Example usage :

```julia
using Norg
norg(HTMLTarget(), "Read {https://github.com/nvim-neorg/norg-specs}[the spec !]")
```
"""
module Norg

using Pkg.Artifacts

"""
The root directory of the Norg specification.
"""
const NORG_SPEC_ROOT = let
    r = artifact"norg-specs-main"
    joinpath(r, first(readdir(r)))
end
"""
Path to the Norg specification.
"""
const NORG_SPEC_PATH = joinpath(NORG_SPEC_ROOT, "1.0-specification.norg")
"""
Path to the Norg standard library.
"""
const NORG_STDLIB_PATH = joinpath(NORG_SPEC_ROOT, "stdlib.norg")
"""
Path to the Norg semantics specification.
"""
const NORG_SEMANTICS_PATH = joinpath(NORG_SPEC_ROOT, "1.0-semantics.norg")

using AbstractTrees

include("kind.jl")
include("strategy.jl")
include("tokens.jl")
include("scanners.jl")
include("tokenize.jl")
include("ast.jl")

using .Kinds
using .Tokens
using .Scanners
using .Tokenize
using .AST

include("utils.jl")
include("match/match.jl")
include("parser/parser.jl")

using .Parser

include("semantics/timestamps.jl")

include("codegen.jl")
using .Codegen


"""
    norg([codegentarget, ] s)

Parse the input `s` to an AST. If codegentarget is included, return the result
of code generation for the given target.

# Examples
```julia-repl
julia> norg("* Hello world!")
NorgDocument
└─ (K"Heading1", 2, 8)
   └─ (K"ParagraphSegment", 4, 7)
      ├─ Hello
      ├─
      ├─ world
      └─ !
julia> norg(HTMLTarget(), "* Hello world!")
<div class="norg"><section id="section-h1-hello-world"><h1 id="h1-hello-world">Hello world&#33;</h1></section><section class="footnotes"><ol></ol></section></div>
```
"""
norg(s)= parse_norg(tokenize(s))
norg(t::T, s) where {T <: Codegen.CodegenTarget} = codegen(t, norg(s))

"""
Easily parse Norg string to an AST. This can be used in *e.g.* Pluto notebooks,
because `Base.show` has a method for "text/html" type mime for ASTs.

julia> norg"* Norg Header 1 Example"
NorgDocument
└─ (K"Heading1", 2, 11)
   └─ (K"ParagraphSegment", 4, 10)
      ├─ Norg
      ├─
      ├─ Header
      ├─
      ├─ 1
      ├─
      └─ Example
"""
macro norg_str(s, t ...)
	norg(s)
end

function Base.show(io::IO, ::MIME"text/html", ast::AST.NorgDocument)
    print(io, codegen(HTMLTarget(), ast))
end

using SnoopPrecompile

@precompile_setup begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    # The following string should call all method specializations.
    s = """* Hello, world!
    First, attached modifiers. *bold*, /italic/, _underline_, -strike-through-, !spoiler!, ^superscript^, ,subscript,, `inlinde code`.

    Then, nestables
    - Hi
    - :
    Hi
    - ::
    Hi
    ---
    - ( ) Undone
    - (x) Done
    - (?) needs further input
    - (!) Urgent
    - (+) recurring
    - (-) In progress
    - (=) On hold
    - (_) cancelled
    - (@ Tue 5th Feb) timestamp extension
    - (< Tue 5th Feb) Due date extenion
    - (> Tue 5th Feb) Start date extenion
    - (# A) Priority extension

    > A quote

    ~ An ordered list.

    Next comes the links. {https://klafyvel.me}[a link]. {12} {* Hello, world!} {/ /home/klafyvel} {# Hello, world!} {:path/to/norg/file:} {? wiki-link} {@ Tue 5th Feb}. Let's not forget [Anchors]{https://klafyvel.me}.

    \$ Definition
    A simple definition

    \$\$ Definition 2
    A longer definition
    \$\$

    ^ Footnote
    Simple footnote

    ^^ Longer Footnote
    Longer Footnote
    ^^

    @code julia
    println("hello")
    @end

    #color red
    test

    +color red
    test
    """

    full_spec = open(NORG_SPEC_PATH, "r") do f
        read(f, String)
    end
    @precompile_all_calls begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        ast = norg(s)
        html = norg(HTMLTarget(), s)
        json = norg(JSONTarget(), s)
        html_spec = norg(HTMLTarget(), s)
        json_spec = norg(JSONTarget(), s)
    end
end

export HTMLTarget, JSONTarget
export @norg_str, norg

end
