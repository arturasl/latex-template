#!/bin/bash

cd ../../

( cd latex-template && vagrant up )

mkdir dia && ln -s ../../dia latex-template/src/dia
mkdir dot && ln -s ../../dot latex-template/src/dot
mkdir gpline && ln -s ../../gpline latex-template/src/gpline
mkdir inkscape && ln -s ../../inkscape latex-template/src/inkscape
mkdir png && ln -s ../../png latex-template/src/png
mkdir tex && ln -s ../../tex latex-template/src/tex

cat <<EOF > Makefile
.PHONY: run all clean

all:
	cd latex-template/; echo 'cd /vagrant && make all && exit' | vagrant ssh

run:
	~/configs/scripts/showme.bash --silent-detached latex-template/output/main.pdf

clean:
	cd latex-template/; echo 'cd /vagrant && make clean && exit' | vagrant ssh

EOF

cat <<EOF > bibliography.bib
@article{test,
	author = "author",
	title = "title ",
	year = 2005
}
EOF
ln -s ../../../bibliography.bib latex-template/src/bib/bibliography.bib

cat <<EOF > tex/main.tex
\documentclass[12pt, a4paper, lithuanian]{article}

\input{conditions}
\input{packages}
\input{pseudocode}
\input{lithuanian}
\input{draftonlycommands}
\input{vusemesterworkstyle}
\input{generalstyle}
\input{newcommands}

\usepackage{listings}
\lstset{breaklines=true}
\newcommand{\wrapingverb}{\lstinline[basicstyle=\normalsize\ttfamily]}

\usepackage{multirow}
\begin{document}

%\input{smth}

\cite{test}
\bibliography{}

\end{document}
EOF
