file?=monads-and-functors.md
pdfname=$(patsubst %.md,%.pdf,$(file))
htmlname=$(patsubst %.md,%.html,$(file))

# Find all markdown files in the current directory
MD_FILES=$(wildcard *.md)
PDF_FILES=$(patsubst %.md,pdfs/%.pdf,$(MD_FILES))

slide:
	npx @marp-team/marp-cli@latest -w $(file) --allow-local-files -o ./slides/$(htmlname) & brave ~/uni/6_semester/afp/afp-exam/slides/$(htmlname)

pdf:
	pandoc $(file) -o pdfs/$(pdfname)

all: $(PDF_FILES)

pdfs/%.pdf: %.md
	@mkdir -p pdfs
	pandoc $< -o $@

.PHONY: slide pdf all
