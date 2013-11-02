# -*- coding: utf-8 -*-
import re
from pygments.lexer import *
from pygments.token import *

class PseudoLexer(RegexLexer):
    name = 'pseudo'
    aliases = ['pseudo']

    keywords = [
        "Ir",
        "Iš",
        "Jei",
        "Kartoti",
        "Kiekvienai",
        "Kiekvienam",
        "Kitaip",
        "Kol",
        "Ne",
        "Paimti",
        "Tada",
        "Taip",
        "Tol",
    ]

    # Operator, Operator.Word, Name.Class, Name.Function, Name.Variable

    #TODO: unicode characters???

    tokens = {
        'root': [
            (r'\'', String, 'string_squote'),
            (r'\"', String, 'string_dquote'),
            (r'(.vestis|i.vestis): .*$', Comment.Single),
            (r'# .*$', Comment.Single),
            (r'\.|,|;|:|\[|\]|\{|\}|\(|\)', Punctuation),
            ('(' + '|'.join(keywords) + r')\b', Keyword.Reserved),
            (r'[-]?[0-9]+', Number),
            (r'\s', Text.Whitespace),
            (r'.', Text),
        ],
        'string_squote': [ (r'[^\']*\'', String, '#pop'), ],
        'string_dquote': [ (r'[^\"]*\"', String, '#pop'), ],
    }
