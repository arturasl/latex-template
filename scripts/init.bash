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
.PHONY: run all clean diff

all:
	cd latex-template/; vagrant up; echo 'cd /vagrant/latex-template && make all && exit' | vagrant ssh

run:
	~/configs/scripts/showme.bash --silent-detached latex-template/output/main.pdf

diff:
	read -p 'Git tag version: ' tag ; cd latex-template/; vagrant up; echo "cd /vagrant/latex-template && make diff GIT_TAG_VERSION=$\$tag && exit" | vagrant ssh

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

( dir='latex-template/src/bib/bibliography.bib'; [ ! -L "$dir" ] && ln -s ../../../bibliography.bib "$dir" )

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

\vumifpaper{}
\title{\large\textbf{Savioptimizavimas reliacinėse duomenų bazių sistemose}\\(angl. Self-optimization in relational database management systems)\\\vspace{0.5cm}\small{Tema}}
\author{
    Artūras Lapinskas\hspace{0.7cm} % kursas nenurodomas
}
\supervisor{lekt. I. Radavičius\hspace{1.2cm}}
\reviewer{doc. dr. V. Tumasonis\hspace{0.1cm}}

\usepackage{listings}
\lstset{breaklines=true}
\newcommand{\wrapingverb}{\lstinline[basicstyle=\normalsize\ttfamily]}

\usepackage{multirow}
\begin{document}

\input{appendix}

\end{document}
EOF

[ ! -f tex/glossary.tex ] && cat <<EOF > tex/glossary.tex
\newglossaryentry{label1} {
  name=name,
  description={desc}
}

\newacronym{label2}{abbriaviation}{long name}
EOF

[ ! -f tex/appendix.tex ] && cat <<EOF > tex/appendix.tex
\cite{test}
\bibliography{}
\printindex
\printglossaries
% \appendix
EOF
