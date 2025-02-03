####################################################################################################
# Configuration
####################################################################################################

# Build configuration
# SHELL=/bin/bash

MAKEFILE = Makefile

BOOK_FOLDER ?= book
BUILD = $(BOOK_FOLDER)/build

CURRENT_DATE = $(shell date '+%Y-%m-%d')
OUTPUT_FILENAME = book-$(CURRENT_DATE)
METADATA = $(BOOK_FOLDER)/meta.yml
CHAPTERS = $(BOOK_FOLDER)/chapters/*.md
FRONTMATTER = $(BOOK_FOLDER)/front_matter/*.md
BACKMATTER = $(BOOK_FOLDER)/back_matter/*.md
IMAGES = $(shell find $(BOOK_FOLDER)/images -type f)
TEMPLATES = $(shell find resources/templates/ -type f)
COVER_IMAGE = $(BOOK_FOLDER)/cover/front.png

BEFORE_TOC = --include-before-body=$(BUILD)/markdown/$(OUTPUT_FILENAME)_front.md

DEFAULT_IMAGE_WIDTH = 50%

# Arguments configuration
TOC = --toc --toc-depth 3
MATH_FORMULAS = --webtex
METADATA_ARGS = --metadata-file $(METADATA)
# FILTER_ARGS = --filter pandoc-crossref
# DEBUG_ARGS = --verbose

# https://github.com/tajmone/pandoc-goodies/tree/master/skylighting/themes
# pandoc --print-highlight-style tango > resources/code-themes/custom.theme
# https://github.com/KDE/syntax-highlighting/tree/master/data/themes
SYNTAX_HIGHLIGHTING_THEME = --highlight-style resources/code-highlight-themes/ayu-light.theme

# Chapters content. Used to prep the consolidated markdown file
BOOK_CONTENT = awk 'FNR==1 && NR!=1 {print "\n\n"}{print}' $(CHAPTERS)
# Use this to add sed filters or other piped commands 
BOOK_CONTENT_FILTERS = tee

# Front matter content. Used to prep the latex files to include before the TOC, a espaced "\newpage \n" is 
# inserted before each include
FRONTMATTER_CONTENT = awk 'FNR==1 && NR!=1 {print "\n\n \\newpage \n"}{print}' $(FRONTMATTER)
# Use this to add sed filters or other piped commands 
FRONTMATTER_CONTENT_FILTERS = tee

# Back matter content. Used to prep the latex files to include after the chapters, a espaced "\newpage \n" is 
# inserted before each include
BACKMATTER_CONTENT = awk 'FNR==1 && NR!=1 {print "\n\n \\newpage \n"}{print}' $(BACKMATTER)
# Use this to add sed filters or other piped commands 
BACKMATTER_CONTENT_FILTERS = tee

# Adds the appendix to the end of the file and overrides the meta.yml file
META_OVERRIDE = -M appendix='$(BUILD)/latex/backmatter'

# Combined arguments

ARGS = $(TOC) $(MATH_FORMULAS) $(METADATA_ARGS) $(FILTER_ARGS) $(DEBUG_ARGS) $(BEFORE_TOC) $(AFTER_TOC) $(SYNTAX_HIGHLIGHTING_THEME) $(META_OVERRIDE)
	
PANDOC_COMMAND = pandoc

# Per-format options

MARKDOWN_ARGS   = --markdown-headings=atx
DOCX_ARGS       = --standalone --reference-doc resources/templates/docx.docx
EPUB_ARGS       = --template resources/templates/epub.html
HTML_ARGS       = --template resources/templates/html.html --standalone --to html5
PDF_PRINT_ARGS  = --template resources/templates/pdf.tex --defaults $(BOOK_FOLDER)/pandoc.yml
PDF_WEB_ARGS    = --template resources/templates/pdf.tex --defaults $(BOOK_FOLDER)/pandoc.yml -V classoption=oneside
BACKMATTER_ARGS = --template resources/templates/include.tex --top-level-division=chapter

# Per-format file dependencies

BASE_DEPENDENCIES     = $(MAKEFILE) $(CHAPTERS) $(METADATA) $(IMAGES) $(TEMPLATES) $(FRONTMATTER) $(BACKMATTER)
MARKDOWN_DEPENDENCIES = $(BASE_DEPENDENCIES)
DOCX_DEPENDENCIES     = $(BASE_DEPENDENCIES)
EPUB_DEPENDENCIES     = $(BASE_DEPENDENCIES)
HTML_DEPENDENCIES     = $(BASE_DEPENDENCIES)
PDF_DEPENDENCIES      = $(BASE_DEPENDENCIES)

####################################################################################################
# Basic actions
####################################################################################################

.PHONY: all
all:	book

.PHONY: book
book:	markdown \
		$(BUILD)/epub/$(OUTPUT_FILENAME).epub \
		$(BUILD)/html/$(OUTPUT_FILENAME).html \
		$(BUILD)/pdf/$(OUTPUT_FILENAME)_web.pdf \
		$(BUILD)/pdf/$(OUTPUT_FILENAME)_print.pdf \
		$(BUILD)/docx/$(OUTPUT_FILENAME).docx

.PHONY: clean
clean:
	rm -r $(BUILD)

####################################################################################################
# Silence output and run in one shell so that venv works
####################################################################################################

.ONESHELL:

.SILENT: all
.SILENT: book
.SILENT: $(BUILD)/markdown/$(OUTPUT_FILENAME).md
.SILENT: $(BUILD)/epub/$(OUTPUT_FILENAME).epub
.SILENT: $(BUILD)/html/$(OUTPUT_FILENAME).html
.SILENT: $(BUILD)/pdf/$(OUTPUT_FILENAME)_web.pdf
.SILENT: $(BUILD)/pdf/$(OUTPUT_FILENAME)_print.pdf
.SILENT: $(BUILD)/docx/$(OUTPUT_FILENAME).docx


####################################################################################################
# Environment
####################################################################################################

.PHONY: environment
environment:
	sudo apt update
	sudo apt install \
			make \
			python3 \
			python3-pip \
			pandoc \
			texlive-fonts-recommended \
			texlive-xetex \
			-y
	pip3 install pyyaml
	@echo "================================================================================"
	@echo "You still need to install the latest pandoc version manually"
	@echo "Most repositories have an outdated version"
	@echo "You can fetch the latest release @ https://github.com/jgm/pandoc/releases/latest"
	@echo "Minimum needed version is 2.19.2"
	@echo "================================================================================"
# sudo apt install texlive-full -y

####################################################################################################
# File builders
####################################################################################################

.PHONY: markdown
markdown:	$(BUILD)/markdown/$(OUTPUT_FILENAME).md

.PHONY: epub
epub:	markdown $(BUILD)/epub/$(OUTPUT_FILENAME).epub

.PHONY: html
html:	markdown $(BUILD)/html/$(OUTPUT_FILENAME).html

.PHONY: pdf
pdf:	markdown \
		$(BUILD)/pdf/$(OUTPUT_FILENAME)_web.pdf \
		$(BUILD)/pdf/$(OUTPUT_FILENAME)_print.pdf

.PHONY: pdf-web
pdf-web:	markdown \
			$(BUILD)/pdf/$(OUTPUT_FILENAME)_web.pdf

.PHONY: pdf-print
pdf-print:	markdown \
			$(BUILD)/pdf/$(OUTPUT_FILENAME)_print.pdf

.PHONY: docx
docx:	markdown $(BUILD)/docx/$(OUTPUT_FILENAME).docx

# Build base markdown file used by other file types
$(BUILD)/markdown/$(OUTPUT_FILENAME).md:	$(MARKDOWN_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/markdown
	mkdir -p $(BUILD)/latex
	$(FRONTMATTER_CONTENT) > $(BUILD)/markdown/$(OUTPUT_FILENAME)_front.md

	$(BOOK_CONTENT) > $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md
	$(BACKMATTER_CONTENT) > $(BUILD)/markdown/$(OUTPUT_FILENAME)_backmatter.md
	
	whoami
	echo "" >> $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md

	# Content filters and prep - moved to python file
	# sed -i 's#../images#$(BOOK_FOLDER)/images#g' $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md
	# sed -i 's#../images#$(BOOK_FOLDER)/images#g' $(BUILD)/markdown/$(OUTPUT_FILENAME)_backmatter.md
	
	python3 -m venv .venv
	. ./.venv/bin/activate
	pip3 install -r requirements.txt

	python3 ./resources/scripts/post_processing.py $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md $(BOOK_FOLDER)
	python3 ./resources/scripts/post_processing.py $(BUILD)/markdown/$(OUTPUT_FILENAME)_backmatter.md $(BOOK_FOLDER)

	# Generate seperate latex file for back matter / appendix

	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_backmatter.md | $(PANDOC_COMMAND) $(BACKMATTER_ARGS) -o $(BUILD)/latex/backmatter.tex
	# cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(MARKDOWN_ARGS) -o $@
	
	@echo "$@ was built"

# Build EPUB
$(BUILD)/epub/$(OUTPUT_FILENAME).epub:		$(EPUB_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/epub

	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(EPUB_ARGS) --epub-cover-image $(COVER_IMAGE) -o $@
	@echo "$@ was built"

# Build HTML
$(BUILD)/html/$(OUTPUT_FILENAME).html:		$(HTML_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/html
	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(HTML_ARGS) -o $@
	cp --parent $(IMAGES) $(BUILD)/html/
	@echo "$@ was built"

# Build Web PDF
$(BUILD)/pdf/$(OUTPUT_FILENAME)_web.pdf:		$(PDF_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/pdf
	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(PDF_WEB_ARGS)  -o $@
	@echo "$@ was built"

# Build Print PDF
$(BUILD)/pdf/$(OUTPUT_FILENAME)_print.pdf:		$(PDF_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/pdf
	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(PDF_PRINT_ARGS) -o $@
	@echo "$@ was built"

# Build DOCX
$(BUILD)/docx/$(OUTPUT_FILENAME).docx:		$(DOCX_DEPENDENCIES)
	@echo "Building $@"
	mkdir -p $(BUILD)/docx
	cat $(BUILD)/markdown/$(OUTPUT_FILENAME)_body.md | $(BOOK_CONTENT_FILTERS) | $(PANDOC_COMMAND) $(ARGS) $(DOCX_ARGS) -o $@
	@echo "$@ was built"
