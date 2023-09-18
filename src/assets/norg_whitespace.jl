const NORG_WHITESPACES = Set(
    Char[
        0x0009, # tab
        # 0x000A, # line feed
        0x000C, # form feed
        0x000D, # carriage return
        0x0020, # space
        0x00A0, # no-break space
        0x1680, # Ogham space mark
        0x2000, # en quad
        0x2001, # em quad
        0x2002, # en space
        0x2003, # em space
        0x2004, # three-per-em space
        0x2005, # four-per-em space
        0x2006, # six-per-em space
        0x2007, # figure space
        0x2008, # punctuation space
        0x2009, # thin space
        0x200A, # hair space
        0x202F, # narrow no-break space
        0x205F, # medium mathematical space
        0x3000,
    ],
)
