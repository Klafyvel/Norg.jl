"""
All the UTF-8 characters that Norg specifies as a whitespace.
"""
const NORG_LINE_ENDING = [
                              Char(0x000A),
                              Char(0x000D),
                              String([Char(0x000D), Char(0x000A)])
                             ]
