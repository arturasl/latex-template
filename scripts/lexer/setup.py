"""
A pseudocode lexer for Pygments
"""
from setuptools import setup

setup(
    name = 'PseudoLexer',
    version = '1.1',
    description = __doc__,
    author = "Arturas",
    install_requires=['pygments'],
    packages = ['pseudolexer', 'asn1lexer'],
    entry_points = '''
[pygments.lexers]
PseudoLexer = pseudolexer:PseudoLexer
Asn1Lexer = asn1lexer:Asn1Lexer
'''
) 
