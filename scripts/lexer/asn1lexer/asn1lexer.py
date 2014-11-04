# -*- coding: utf-8 -*-
import re
from pygments.lexer import *
from pygments.token import *

class Asn1Lexer(RegexLexer):
    name = 'asn1'
    aliases = ['asn1']

    keywords = [
        'SET',
        'SEQUENCE',
        "CHOICE",
        "NULL",
    ]

    # Operator, Operator.Word, Name.Class, Name.Function, Name.Variable

    tokens = {
        'root': [
            (r'\'', String, 'string_squote'),
            (r'\"', String, 'string_dquote'),
            (r'-- .*$', Comment.Single),
            (r'\.|,|;|:|\[|\]|\{|\}|\(|\)', Punctuation),
            ('(' + '|'.join(keywords) + r')\b', Keyword.Reserved),
            (r'\b[A-Z][a-z0-9A-Z]*\b', Name.Entity),
            (r'\b[a-z][a-z0-9A-Z]*\b', Text),
            (r'[-]?[0-9]+', Number),
            (r'\s', Text.Whitespace),
            (r'.', Text),
        ],
        'string_squote': [ (r'[^\']*\'', String, '#pop'), ],
        'string_dquote': [ (r'[^\"]*\"', String, '#pop'), ],
    }
