#!/bin/bash

cd ../../

( cd latex-template && vagrant destroy --force && vagrant up --provision )

for dir in dia dot gpline inkscape png tex pseudocode umlet pdfimg gimp; do
	[ ! -d "$dir" ]                      && mkdir "$dir"
	[ ! -L "latex-template/src/${dir}" ] && ln -s "../../${dir}" "latex-template/src/${dir}"
done

cat <<EOF > Makefile
.PHONY: run all clean diff
FN_IN_VAGRANT = cd latex-template/; vagrant up; echo 'cd /vagrant/latex-template && \$(1) && exit' | vagrant ssh | grep -v '^(\\.\\?/'

all:
	\$(call FN_IN_VAGRANT,make all)

run:
	~/configs/scripts/showme.bash --silent-detached latex-template/output/main.pdf

diff:
	read -p 'Git tag version: ' tag ; cd latex-template/; vagrant up; echo "cd /vagrant/latex-template && make diff GIT_TAG_VERSION=$\$tag && exit" | vagrant ssh

clean:
	\$(call FN_IN_VAGRANT,make clean)
EOF

[ ! -f bibliography.bib ] && cat <<EOF > bibliography.bib
@article{test,
	author = "author",
	title = "title ",
	year = 2005
}
EOF

( dir='latex-template/src/bib/bibliography.bib'; [ ! -L "$dir" ] && ln -s ../../../bibliography.bib "$dir" )

[ ! -f tex/main.tex ] && cat <<EOF > tex/main.tex
\documentclass[12pt, a4paper, lithuanian]{article}

\input{conditions}
\input{packages}
\input{pseudocode}
\input{unicode}
\input{lithuanian}
\input{draftonlycommands}
\input{vusemesterworkstyle}
\input{newcommands}
\input{generalstyle}

\vumifpaper{}
\title{\large\textbf{Savioptimizavimas reliacinėse duomenų bazių sistemose}\\\\(angl. Self-optimization in relational database management systems)\\\\\vspace{0.5cm}\small{Tema}}
\author{Artūras Lapinskas}
\supervisor{lekt. I. Radavičius}
\reviewer{lekt. A. Stočkus}

\usepackage{listings}
\lstset{breaklines=true}
\newcommand{\wrapingverb}{\lstinline[basicstyle=\normalsize\ttfamily]}

\usepackage{multirow}
\begin{document}

\input{appendix}

\end{document}
EOF

[ ! -f tex/glossary.tex ] && cat <<EOF > tex/glossary.tex
\glsDef        {ABC1}    {ABC Name}  {ABC Description}
\glsDefAndAcc  {ABC2}    {ABC Name}  {ABC Description}
EOF

[ ! -f tex/appendix.tex ] && cat <<EOF > tex/appendix.tex
\nocite{*}
\bibliography{}
\printindex
\printglossaries
% \appendix
EOF
