BASE = slide
PDF = $(BASE).pdf
TEX = $(BASE).tex
BIB = $(BASE).bib

STY_SRCS := $(wildcard *.sty)
FIG_SRCS := $(wildcard fig/*.tex)

.PHONY: clean

all: $(PDF)

$(PDF): $(STY_SRCS) $(FIG_SRCS) $(TEX) $(BIB)
	latexmk $(BASE)

view: $(PDF)
	latexmk -pv

clean:
	git clean -xfd

distclean:
	latexmk -C
