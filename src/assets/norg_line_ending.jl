"""
All the UTF-8 characters that Norg specifies as a whitespace.
"""
const NORG_LINE_ENDING = String[
    string(Char(0x000A)),
    string(Char(0x000D)),
    String([Char(0x000D), Char(0x000A)]),
]
