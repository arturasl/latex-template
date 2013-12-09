#!/bin/bash

cd ../../

( cd latex-template && vagrant up )

for dir in dia dot gpline inkscape png tex; do
	if [ ! -d "$dir" ]; then
		mkdir "$dir"
		ln -s "../../${dir}" "latex-template/src/${dir}"
	fi
done

cat <<EOF > Makefile
.PHONY: run all clean

all:
	cd latex-template/; vagrant up; echo 'cd /vagrant/latex-template && make all && exit' | vagrant ssh

run:
	~/configs/scripts/showme.bash --silent-detached latex-template/output/main.pdf

clean:
	cd latex-template/; vagrant up; echo 'cd /vagrant/latex-template && make clean && exit' | vagrant ssh

EOF

[ ! -f bibliography.bib ] && cat <<EOF > bibliography.bib
@article{test,
	author = "author",
	title = "title ",
	year = 2005
}
EOF
ln -s ../../../bibliography.bib latex-template/src/bib/bibliography.bib

[ ! -f tex/main.tex ] && cat <<EOF > tex/main.tex
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
