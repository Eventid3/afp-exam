file?=monads-and-functors.md
pdfname=$(patsubst %.md,%.pdf,$(file))
htmlname=$(patsubst %.md,%.html,$(file))

# Find all markdown files in the current directory
MD_FILES=$(wildcard *.md)
HTML_FILES=$(patsubst %.md,slides/%.html,$(MD_FILES))

slide:
	npx @marp-team/marp-cli@latest -w $(file) --allow-local-files -o ./slides/$(htmlname) & brave ~/uni/6_semester/afp/slides/$(htmlname)

all: $(HTML_FILES)
	@mkdir -p slides/img
	@cp img/* slides/img/

slides/%.html: %.md
	@mkdir -p slides
	npx @marp-team/marp-cli@latest $< --allow-local-files -o $@

.PHONY: slide pdf all
