# allow including files (from latex) from these directories
TEXINPUTS := ./src/styles/:./src/tex/:./src/headers/:./src/bib/:${TEXINPUTS}
export TEXINPUTS

# do not add separator at the end
OBJDIR := obj
OUTPUTDIR := output
MAIN_FILE := main

# all files in psedocode and dot directories should start with these
PSEUDOCODEDIR := pseudocode
DIADIR := dia
DOTDIR := dot
INKSCAPEDIR := inkscape
GPLINEDIR := gpline
TEXDIR := tex
UMLETDIR := umlet

# find all psedocode (or any other special file) files in ./src/pseudocode
# obj files will be these files put into obj (preserving relative directory from src) directory and with .tex substituted with .pdf
FN_MAKE_FILE_LIST = $(addprefix $(OBJDIR)/$(1)/,$(shell find ./src/$(1)/ -name '*.$(2)' | sed -e 's/\.$(2)/.pdf/g' | sed -e 's/\.\/src\/[^/]\+\///g'))
PSEDOCODEFILES := $(addprefix $(OBJDIR)/$(PSEUDOCODEDIR)/,$(notdir $(shell find ./src/$(PSEUDOCODEDIR)/ -type f -a ! \( -name 'README.mkd' -o -name 'Makefile' \) | sed -e 's/\(.*\)\..*/\1.pdf/g' )))
DOTFILES := $(addprefix $(OBJDIR)/$(DOTDIR)/,$(notdir $(shell find ./src/$(DOTDIR)/ -name '*.dot' | sed -e 's/\.dot/.pdf/g' )))
DIAFILES := $(addprefix $(OBJDIR)/$(DIADIR)/,$(notdir $(shell find ./src/$(DIADIR)/ -name '*.dia' | sed -e 's/\.dia/.pdf/g' )))
UMLETFILES := $(call FN_MAKE_FILE_LIST,$(UMLETDIR),uxf)
INKSCAPEFILES := $(addprefix $(OBJDIR)/$(INKSCAPEDIR)/,$(notdir $(shell find ./src/$(INKSCAPEDIR)/ -name '*.svg' | sed -e 's/\.svg/.pdf/g' )))
GPLINEFILES := $(addprefix $(OBJDIR)/$(GPLINEDIR)/,$(notdir $(shell find ./src/$(GPLINEDIR)/ -name '*.csv' | sed -e 's/\.csv/.pdf/g' )))

# set up compiler options
LATEXPARAMS := -shell-escape -file-line-error -interaction=nonstopmode --output-directory=$(OBJDIR)
CC := xelatex
#CC := pdflatex

# -min-crossref=1 after any \cite command appropriative bib item will appear
BIBTEX := bibtex -min-crossref=1 -terse

GLOSSARIES := makeglossaries -L lithuanian

.PHONY: clean run all objstructure

all: objstructure $(OUTPUTDIR)/$(MAIN_FILE).pdf

objstructure:
	echo "${UMLETFILES}"
	mkdir -p \
		$(OUTPUTDIR) \
		$(OBJDIR)/$(PSEUDOCODEDIR) \
		$(OBJDIR)/$(DOTDIR) \
		$(OBJDIR)/$(DIADIR) \
		$(OBJDIR)/$(UMLETDIR) \
		$(OBJDIR)/$(INKSCAPEDIR) \
		$(OBJDIR)/$(GPLINEDIR)

$(OUTPUTDIR)/$(MAIN_FILE).pdf: src/$(TEXDIR)/*.tex src/headers/*.tex $(PSEDOCODEFILES) $(DOTFILES) $(DIAFILES) $(UMLETFILES) $(INKSCAPEFILES) $(GPLINEFILES)
	bash -c "rm -f $(OBJDIR)/$(MAIN_FILE).{glg,gls,glo,alg,acr,acn,xdy}" # xindy somehow fails without fully recreating everythin
	# make
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	# bibliography
	$(BIBTEX) $(OBJDIR)/$(MAIN_FILE)
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	# glossaries
	( cd $(OBJDIR) && $(GLOSSARIES) $(MAIN_FILE) )
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	# move
	mv $(OBJDIR)/$(MAIN_FILE).pdf $(OUTPUTDIR)

$(OBJDIR)/$(PSEUDOCODEDIR)/%.pdf: src/$(PSEUDOCODEDIR)/%.* src/headers/*.tex
	./scripts/code_to_latex.bash "$<" "src/$(PSEUDOCODEDIR)/tmp" ./src/headers/pseudocode_before.tex ./src/headers/pseudocode_after.tex
	# before real input file define what outputdirectory to use (needed for minted)
	${CC} $(LATEXPARAMS) --output-directory=$(OBJDIR)/$(PSEUDOCODEDIR) -jobname=$(basename $(notdir $@)) "\def\myoutputdirectory{$(OBJDIR)/$(PSEUDOCODEDIR)}\input{src/$(PSEUDOCODEDIR)/tmp}"
	rm -rf "src/$(PSEUDOCODEDIR)/tmp"

diff:
	mkdir -p ./tmp/
	( cd .. && git checkout "$(GIT_TAG_VERSION)" ) && ./scripts/latexpand/latexpand --output ./tmp/main_old.tex ./src/tex/main.tex
	( cd .. && git checkout master ) && ./scripts/latexpand/latexpand --output ./tmp/main_cur.tex ./src/tex/main.tex
	(\
		SAFE_FOR_DIFF="$(shell grep '\\newcommand{\\[[:alpha:]]\+}{\\emph.\+xspace\}' --only-matching ./tmp/main_cur.tex | cut -b14- | sed -e 's/}.\+//g' | tr '\n' ',')" \
		&& SAFE_FOR_DIFF="$${SAFE_FOR_DIFF}$(shell grep '\\newcommand{\\[[:alpha:]]\+}{\\emph.\+xspace\}' --only-matching ./tmp/main_old.tex | cut -b14- | sed -e 's/}.\+//g' | tr '\n' ',')" \
		&& latexdiff --exclude-textcmd="section,subsection,subsubsection" --append-safecmd="$${SAFE_FOR_DIFF}shortform,eng" --encoding=utf-8 --packages=ulem tmp/main_old.tex tmp/main_cur.tex > diffs.tex \
	)
	sed -i'' -e '/\\RequirePackage\[normalem\]{ulem}/d' diffs.tex
	sed -i'' -e '/\\usepackage\[style=german,strict=true,maxlevel=2\]/d' diffs.tex
	sed -i'' -e '/\\MakeOuterQuote/d' diffs.tex
	sed -i'' -e '/\\xspaceaddexceptions/d' diffs.tex
	$(CC) $(LATEXPARAMS) diffs.tex
	$(BIBTEX) $(OBJDIR)/diffs
	$(CC) $(LATEXPARAMS) diffs.tex
	$(CC) $(LATEXPARAMS) diffs.tex
	mv $(OBJDIR)/diffs.pdf output/diffs.pdf
	rm -rf diffs.*
	rm -rf ./tmp/

$(OBJDIR)/$(DOTDIR)/%.pdf: src/$(DOTDIR)/%.dot
	# read first line of dot file - if it contains comment (//cmd: custom command) strip it and use its contents as dot command
	$(eval CUSTOMDOTCMD := $(shell head -n 1 $< | grep '//cmd: ' | sed -e 's/\/\/cmd: //g'))
	./scripts/topdf.bash $< $(OBJDIR)/$(DOTDIR)/$(basename $(notdir $<)).pdf "$(CUSTOMDOTCMD)"

$(OBJDIR)/$(DIADIR)/%.pdf: src/$(DIADIR)/%.dia
	./scripts/topdf.bash $< $(OBJDIR)/$(DIADIR)/$(basename $(notdir $<)).pdf

$(OBJDIR)/$(UMLETDIR)/%.pdf: src/$(UMLETDIR)/%.uxf
	mkdir -p '$(OBJDIR)/$(UMLETDIR)/$(dir $(shell echo '$<' | sed -e 's/src\/[^/]\+\///g'))'
	./scripts/topdf.bash $< $(OBJDIR)/$(UMLETDIR)/$(basename $(shell echo '$<' | sed -e 's/src\/[^/]\+\///g')).pdf

$(OBJDIR)/$(DIADIR)/%.pdf: src/$(DIADIR)/%.dia
	./scripts/topdf.bash $< $(OBJDIR)/$(DIADIR)/$(basename $(notdir $<)).pdf

$(OBJDIR)/$(INKSCAPEDIR)/%.pdf: src/$(INKSCAPEDIR)/%.svg
	./scripts/topdf.bash $< $(OBJDIR)/$(INKSCAPEDIR)/$(basename $(notdir $<)).pdf inkscape

$(OBJDIR)/$(GPLINEDIR)/%.pdf: src/$(GPLINEDIR)/%.csv
	./scripts/topdf.bash $< $(OBJDIR)/$(GPLINEDIR)/$(basename $(notdir $<)).pdf

run:
	evince $(OUTPUTDIR)/$(MAIN_FILE).pdf

clean:
	rm -rf $(OBJDIR)/*
	rm -rf $(OUTPUTDIR)/*
