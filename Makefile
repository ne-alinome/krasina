# Makefile of _Krasina_

# By Marcos Cruz (programandala.net)
# http://ne.alinome.net

# Last modified 202011091658
# See change log at the end of the file

# ==============================================================
# Requirements {{{1

# Asciidoctor (by Dan Allen, Sarah White et al.)
#   http://asciidoctor.org

# Asciidoctor EPUB3 (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-epub3

# Asciidoctor PDF (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-pdf

# dbtoepub
#   http://docbook.sourceforge.net/release/xsl/current/epub/README

# ebook-convert
#   manual.calibre-ebook.com/generated/en/ebook-convert.html

# ImageMagick (by ImageMagick Studio LCC)
#   http://imagemagick.org

# img2pdf (by Johannes 'josch' Schauer)
#   https://gitlab.mister-muffin.de/josch/img2pdf

# Pandoc (by John MacFarlane)
#   http://pandoc.org

# xsltproc
#   http://xmlsoft.org/xslt/xsltproc.html

# ==============================================================
# Config {{{1

VPATH=./src:./target

book=krasina
title="Krasina"
subtitle="Original raconta ex li subterrania de Moravian Carst"
book_author="Jan A. Kajš"
publisher="ne alinome"
description=
lang=ie

# ==============================================================
# Interface {{{1

.PHONY: recommended
recommended: epuba pdfa4 thumb

.PHONY: all
all: azw3 epub pdf thumb

.PHONY: azw3
azw3: target/$(book).adoc.epub.azw3

.PHONY: epub
epub: epuba epubp

.PHONY: epuba
epuba: target/$(book).adoc.epub

.PHONY: epubd
epubd: target/$(book).adoc.dbk.dbtoepub.epub

.PHONY: epubp
epubp: target/$(book).adoc.dbk.pandoc.epub

.PHONY: epubx
epubx: target/$(book).adoc.dbk.xsltproc.epub

.PHONY: md
md: target/$(book).adoc.dbk.pandoc.md

.PHONY: odt
odt: target/$(book).adoc.dbk.pandoc.odt

.PHONY: pdf
pdf: pdfa4

.PHONY: pdfa4
pdfa4: target/$(book).adoc._a4.pdf

.PHONY: pdfl
pdfl: target/$(book).adoc._letter.pdf

.PHONY: dbk
dbk: target/$(book).adoc.dbk

.PHONY: cover
cover: target/$(book)_cover.jpg

.PHONY: html
html: target/$(book).adoc.html

.PHONY: thumb
thumb: target/$(book)_cover_thumb.jpg

.PHONY: clean
clean:
	rm -fr target/* tmp/*

# ==============================================================
# Convert Asciidoctor to PDF {{{1

.SECONDARY: tmp/$(book)_cover.jpg.pdf

target/%.adoc._a4.pdf: src/%.adoc tmp/$(book)_cover.jpg.pdf
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc._letter.pdf: src/%.adoc tmp/$(book)_cover.jpg.pdf
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to EPUB {{{1

# XXX REMARK -- Not used yet, because asciidoctor-epub3 needs the chapters to
# be splitted in independent files, and included into the main source.

target/%.adoc.epub: src/%.adoc target/$(book)_cover.jpg
	asciidoctor-epub3 \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook {{{1

target/%.adoc.dbk: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to HTML {{{1

target/%.adoc.html: src/%.adoc
	asciidoctor --backend=html5 --out-file=$@ $<

# ==============================================================
# Convert DocBook to EPUB {{{1

# ------------------------------------------------
# With dbtoepub {{{2

# XXX TODO -- Add the cover image. There's no parameter to do it.

target/$(book).adoc.dbk.dbtoepub.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml
	dbtoepub \
		--output $@ $<

# ------------------------------------------------
# With pandoc {{{2

target/$(book).adoc.dbk.pandoc.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/pandoc_epub_template.txt \
	src/pandoc_epub_stylesheet.css \
	target/$(book)_cover.jpg
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=autor:$(book_author) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--epub-cover-image=target/$(book)_cover.jpg \
		--output $@ $<

# ------------------------------------------------
# With xsltproc {{{2

%.adoc.dbk.xsltproc.epub: %.adoc.dbk target/$(book)_cover.jpg
	rm -fr tmp/xsltproc/* && \
	xsltproc \
		--output tmp/xsltproc/ \
		/usr/share/xml/docbook/stylesheet/docbook-xsl/epub/docbook.xsl \
		$< && \
	echo -n application/epub+zip > tmp/xsltproc/mimetype && \
	cd tmp/xsltproc/ && \
	zip -0 -X ../../$@.zip mimetype && \
	zip -rg9 ../../$@.zip META-INF && \
	zip -rg9 ../../$@.zip OEBPS && \
	cd - && \
	mv $@.zip $@

# XXX TODO -- Add the cover image. Beside copying the image, the files
# <toc.ncx> and <content.opf> must be modified:
#
#	cp -f target/$(book)_cover.jpg tmp/xsltproc/OEBPS/cover-image.jpg && \

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
#
#  cp -f src/xsltproc/stylesheet.css tmp/xsltproc/OEBPS/ && \

# ==============================================================
# Convert DocBook to OpenDocument {{{1

target/$(book).adoc.dbk.pandoc.odt: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/pandoc_odt_template.txt
	pandoc \
		--from docbook \
		--to odt \
		--template=src/pandoc_odt_template.txt \
		--variable=lang:$(lang) \
		--variable=autor:$(book_author) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--output $@ $<

# ==============================================================
# Convert DocBook to Pandoc's Markdown {{{1

target/$(book).adoc.dbk.pandoc.md: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml
	pandoc \
		--from docbook \
		--to markdown \
		--standalone \
		--variable=lang:$(lang) \
		--variable=autor:$(book_author) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--output $@ $<

# ==============================================================
# Convert EPUB to AZW3 {{{1

target/%.epub.azw3: target/%.epub
	ebook-convert $< $@

# ==============================================================
# Create the cover image {{{1

# ------------------------------------------------
# Create the canvas and texts {{{2

font=Linux-Libertine-O
publisher_font=Helvetica
background=black
fill=white
strokewidth=4

tmp/book_cover.canvas.jpg:
	convert \
		-size 1200x1600 \
		canvas:$(background) \
		$@

tmp/book_cover.title.jpg:
	convert \
		-background $(background) \
		-fill $(fill) \
		-font $(font) \
		-pointsize 175 \
		-size 1200x \
		-gravity center \
		caption:$(title) \
		$@

tmp/book_cover.subtitle.jpg:
	convert \
		-background $(background) \
		-fill $(fill) \
		-font $(font) \
		-pointsize 50 \
		-size 700x \
		-gravity center \
		caption:$(subtitle) \
		$@

tmp/book_cover.author.jpg:
	convert \
		-background $(background) \
		-fill $(fill) \
		-font $(font) \
		-pointsize 90 \
		-size 1200x \
		-gravity center \
		caption:$(book_author) \
		$@

tmp/book_cover.publisher.jpg:
	convert \
		-background $(background) \
		-fill $(fill) \
		-font $(publisher_font) \
		-pointsize 24 \
		-gravity east \
		-size 128x \
		caption:$(publisher) \
		$@

# ------------------------------------------------
# Create the cover image {{{2

target/$(book)_cover.jpg: \
	tmp/book_cover.canvas.jpg \
	tmp/book_cover.title.jpg \
	tmp/book_cover.subtitle.jpg \
	tmp/book_cover.author.jpg \
	tmp/book_cover.publisher.jpg \
	img/moravian_carst.jpg
	composite -gravity north  -geometry +0+070 tmp/book_cover.title.jpg tmp/book_cover.canvas.jpg $@
	composite -gravity north  -geometry +0+250 tmp/book_cover.subtitle.jpg $@ $@
	composite -gravity south  -geometry +0+110 tmp/book_cover.author.jpg $@ $@
	composite -gravity southeast -geometry +048+048 tmp/book_cover.publisher.jpg $@ $@
	composite -gravity center -geometry +0+070 img/moravian_carst.jpg $@ $@

# ------------------------------------------------
# Convert the cover image to PDF {{{2

# This is needed in order to make sure the cover image ocuppies the whole page
# in the PDF versions of the book.

tmp/%_cover.jpg.pdf: target/%_cover.jpg
	img2pdf --output $@ --border 0 $<

# ------------------------------------------------
# Create a thumb version of the cover image {{{2

%_cover_thumb.jpg: %_cover.jpg
	convert $< -resize 190x $@

# ==============================================================
# Build the release archives {{{1

version_file=src/$(book).adoc

include Makefile.release

# ==============================================================
# Change log {{{1

# 2019-03-24: Start.
#
# 2019-04-12: Add interface rules for OpenDocument and DocBook. Set `lang`.
# Consider DocBook a target instead of an intermediate format. Make the clean
# rule recursive.
#
# 2020-02-23: Add a cover image.
#
# 2020-02-24: Deactivate EPUB made with xsltproc and dbtoepub, which don't
# include the cover image yet. Deactivate also the ODT format. Make only the
# formats that can include the cover image. Improve the cover image: add
# subtitle, change font, size and position of texts.
#
# 2020-03-16: Fix typo.
#
# 2020-03-30: Update the publisher.
#
# 2020-11-03: Shorten variable. Improve some rules. Move cover images to
# <target>. Activate the building of EPUB with Asciidoctor EPUB3. Add rule to
# build only the thumb cover image. Add rule to build the recommended formats.
# Build also AZW3, from EPUB. Replace DocBook extension ".xml" with ".dbk".
# Improve the extensions to indicate the size of PDF. Update requirements.
#
# 2020-11-04: Add the publisher to the cover. Fix the thumb cover rule.
#
# 2020-11-05: Include <Makefile.release>.
#
# 2020-11-06: Add rule to convert from DocBook to Pandoc's Markdown.
#
# 2020-11-07: Add rule to convert from Asciidoctor to HTML.
#
# 2020-11-09: Prevent the PDF cover from being built every time.
