# Wildbits F256 6809 Reference Manual
#
#   make           register tables, examples and the draft PDF
#   make release   PDF that fails if any \verify{} text is left
#   make regs      regenerate tables and equates from data/registers
#   make examples  assemble the examples (LWASM=... picks the assembler;
#                  the NitrOS-9 examples need NITROS9DIR=... as well)

MAIN = f256jr_6809_ref

all: pdf examples

regs:
	python3 tools/regs.py

pdf: regs
	cd tex && latexmk -pdf -interaction=nonstopmode $(MAIN).tex

release: regs
	cd tex && latexmk -pdf -g -interaction=nonstopmode \
		-pdflatex='pdflatex %O "\def\releasebuild{}\input{%S}"' $(MAIN).tex

examples: regs
	$(MAKE) -C examples/raw
ifdef NITROS9DIR
	$(MAKE) -C examples/nos9
else
	@echo "Skipping examples/nos9: set NITROS9DIR to a NitrOS-9 tree to build them"
endif

clean:
	cd tex && latexmk -c $(MAIN).tex
	$(MAKE) -C examples/raw clean
	$(MAKE) -C examples/nos9 clean

.PHONY: all regs pdf release examples clean
