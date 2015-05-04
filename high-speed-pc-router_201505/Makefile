BASE = slide
PDF = $(BASE).pdf
TEX = $(BASE).tex
BIB = $(BASE).bib

STY_SRCS := $(wildcard *.sty)
FIG_SRCS := $(wildcard fig/*.tex)
PLT_SRCS := $(wildcard plt/*.gnu)

.PHONY: clean

all: $(PDF)

$(FIG_SRCS): $(PLT_SRCS)
	(cd plt && for src in *.gnu; do gnuplot $$src; done)

$(PDF): $(STY_SRCS) $(FIG_SRCS) $(TEX) $(BIB)
	latexmk $(BASE)

view: $(PDF)
	latexmk -pv

clean:
	git clean -xfd

distclean:
	latexmk -C
