# allow including files (from latex) from these directories
TEXINPUTS := ./src:./src/styles/:./src/tex/:./src/headers/:./src/bib/:${TEXINPUTS}
export TEXINPUTS

# do not add separator at the end
OBJDIR := obj
OUTPUTDIR := output
MAIN_FILE := main

# all files in pseudocode and dot directories should start with these
PSEUDOCODEDIR := pseudocode
DIADIR := dia
DOTDIR := dot
INKSCAPEDIR := inkscape
GPLINEDIR := gpline
TEXDIR := tex
UMLETDIR := umlet
PDFDIR := pdfimg
GIMPDIR := gimp

# find all pseudocode (or any other special file) files in ./src/pseudocode
# obj files will be these files put into obj (preserving relative directory from src) directory and with .tex substituted with .pdf
FN_MAKE_FILE_LIST = $(addprefix $(OBJDIR)/$(1)/,$(shell find ./src/$(1)/ -name '*.$(2)' -a ! \( -name 'README.mkd' -o -name 'Makefile' -o -name '.*' \) | sed -e 's/\(.*\)\..*/\1.pdf/g' | sed -e 's/\.\/src\/[^/]\+\///g'))
FN_OUTPUTDIR_FOR_FILE = $(OBJDIR)/$(1)/$(dir $(shell echo '$(2)' | sed -e 's/src\/[^/]\+\///g'))
FN_OUTPUTNAME_FOR_FILE = $(OBJDIR)/$(1)/$(basename $(shell echo '$(2)' | sed -e 's/src\/[^/]\+\///g')).pdf

PSEUDOCODEFILES := $(call FN_MAKE_FILE_LIST,$(PSEUDOCODEDIR),*)
DOTFILES := $(call FN_MAKE_FILE_LIST,$(DOTDIR),dot)
DIAFILES := $(call FN_MAKE_FILE_LIST,$(DIADIR),dia)
UMLETFILES := $(call FN_MAKE_FILE_LIST,$(UMLETDIR),uxf)
PDFFILES := $(call FN_MAKE_FILE_LIST,$(PDFDIR),pdf)
INKSCAPEFILES := $(call FN_MAKE_FILE_LIST,$(INKSCAPEDIR),svg)
GIMPFILES := $(addprefix $(OBJDIR)/$(GIMPDIR)/,$(notdir $(shell find ./src/$(GIMPDIR)/ -name '*.xcf' | sed -e 's/\.xcf/.png/g' )))
GPLINEFILES := $(call FN_MAKE_FILE_LIST,$(GPLINEDIR),csv)

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
	mkdir -p \
		$(OUTPUTDIR) \
		$(OBJDIR)/$(PSEUDOCODEDIR) \
		$(OBJDIR)/$(DOTDIR) \
		$(OBJDIR)/$(DIADIR) \
		$(OBJDIR)/$(UMLETDIR) \
		$(OBJDIR)/$(PDFDIR) \
		$(OBJDIR)/$(INKSCAPEDIR) \
		$(OBJDIR)/$(GPLINEDIR) \
		$(OBJDIR)/$(GIMPDIR)

$(OUTPUTDIR)/$(MAIN_FILE).pdf: src/$(TEXDIR)/*.tex src/headers/*.tex $(PSEUDOCODEFILES) $(DOTFILES) $(DIAFILES) $(PDFFILES) $(INKSCAPEFILES) $(GPLINEFILES) $(UMLETFILES) $(GIMPFILES)
	bash -c "rm -f $(OBJDIR)/$(MAIN_FILE).{glg,gls,glo,alg,acr,acn,xdy}" # xindy somehow fails without fully recreating everythin
	# make
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	# glossaries
	if [ -f ../tex/glossary.tex ]; then \
		( cd $(OBJDIR) && $(GLOSSARIES) $(MAIN_FILE) ) ; \
		$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex ; \
	fi;
	# bibliography
	if [ -f ../bibliography.bib ]; then \
		$(BIBTEX) $(OBJDIR)/$(MAIN_FILE) ; \
	fi;
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	$(CC) $(LATEXPARAMS) src/$(TEXDIR)/$(MAIN_FILE).tex
	# move
	mv $(OBJDIR)/$(MAIN_FILE).pdf $(OUTPUTDIR)

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

$(OBJDIR)/$(PSEUDOCODEDIR)/%.pdf: src/$(PSEUDOCODEDIR)/%.* src/headers/*.tex
	./scripts/code_to_latex.bash "$<" "src/$(PSEUDOCODEDIR)/tmp" ./src/headers/pseudocode_before.tex ./src/headers/pseudocode_after.tex
	mkdir -p '$(call FN_OUTPUTDIR_FOR_FILE,$(PSEUDOCODEDIR),$<)'
	# before real input file define what outputdirectory to use (needed for minted)
	${CC} $(LATEXPARAMS) '--output-directory=$(call FN_OUTPUTDIR_FOR_FILE,$(PSEUDOCODEDIR),$<)' -jobname=$(basename $(notdir $@)) "\def\myoutputdirectory{$(call FN_OUTPUTDIR_FOR_FILE,$(PSEUDOCODEDIR),$<)}\input{src/$(PSEUDOCODEDIR)/tmp}"
	rm -rf "src/$(PSEUDOCODEDIR)/tmp"

$(OBJDIR)/$(DOTDIR)/%.pdf: src/$(DOTDIR)/%.dot
	# read first line of dot file - if it contains comment (//cmd: custom command) strip it and use its contents as dot command
	$(eval CUSTOMDOTCMD := $(shell head -n 1 $< | sed -e 's/[[:space:]]*//g' | grep '//cmd:' | sed -e 's/\/\/cmd://g'))
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(DOTDIR),$<) "$(CUSTOMDOTCMD)"

$(OBJDIR)/$(DIADIR)/%.pdf: src/$(DIADIR)/%.dia
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(DIADIR),$<)

$(OBJDIR)/$(GIMPDIR)/%.png: src/$(GIMPDIR)/%.xcf
	xcf2png $< -o $(OBJDIR)/$(GIMPDIR)/$(basename $(notdir $<)).png

$(OBJDIR)/$(UMLETDIR)/%.pdf: src/$(UMLETDIR)/%.uxf
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(UMLETDIR),$<)

$(OBJDIR)/$(PDFDIR)/%.pdf: src/$(PDFDIR)/%.pdf
	cp $< $(call FN_OUTPUTNAME_FOR_FILE,$(PDFDIR),$<)

$(OBJDIR)/$(DIADIR)/%.pdf: src/$(DIADIR)/%.dia
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(DIADIR),$<)

$(OBJDIR)/$(INKSCAPEDIR)/%.pdf: src/$(INKSCAPEDIR)/%.svg
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(INKSCAPEDIR),$<) inkscape

$(OBJDIR)/$(GPLINEDIR)/%.pdf: src/$(GPLINEDIR)/%.csv
	./scripts/topdf.bash $< $(call FN_OUTPUTNAME_FOR_FILE,$(GPLINEDIR),$<)

run:
	evince $(OUTPUTDIR)/$(MAIN_FILE).pdf

clean:
	rm -rf $(OBJDIR)/*
	rm -rf $(OUTPUTDIR)/*
