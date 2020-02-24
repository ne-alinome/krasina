# Makefile of _Krasina_

# By Marcos Cruz (programandala.net)
# http://ne.alinome.net

# Last modified 202002241231
# See change log at the end of the file

# ==============================================================
# Requirements

# - Asciidoctor
# - asciidoctor-pdf
# - dbtoepub
# - ImageMagick  
# - img2pdf  
# - Pandoc
# - xsltproc

# ==============================================================
# Config

VPATH=./src:./target

book_basename=krasina
title="Krasina"
book_author="Jan A. Kajš"
publisher="ne.alinome"
description=
lang=ie

# ==============================================================
# Interface

.PHONY: all
all: epub pdf

.PHONY: epub
epub: epubp

# XXX REMARK -- Not used yet:
.PHONY: epuba
epuba: target/$(book_basename).adoc.epub

.PHONY: epubd
epubd: target/$(book_basename).adoc.xml.dbtoepub.epub

.PHONY: epubp
epubp: target/$(book_basename).adoc.xml.pandoc.epub

.PHONY: epubx
epubx: target/$(book_basename).adoc.xml.xsltproc.epub

.PHONY: odt
odt: target/$(book_basename).adoc.xml.pandoc.odt

.PHONY: pdf
pdf: pdfa4

.PHONY: pdfa4
pdfa4: target/$(book_basename).adoc.a4.pdf

.PHONY: pdfletter
pdfletter: target/$(book_basename).adoc.letter.pdf

.PHONY: xml
xml: target/$(book_basename).adoc.xml

.PHONY: cover
cover: tmp/book_cover.jpg

.PHONY: clean
clean:
	rm -fr target/* tmp/*

# ==============================================================
# Convert Asciidoctor to PDF

target/%.adoc.a4.pdf: src/%.adoc tmp/book_cover.pdf
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc.letter.pdf: src/%.adoc tmp/book_cover.pdf
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to EPUB

# XXX REMARK -- Not used yet, because asciidoctor-epub3 needs the chapters to
# be splitted in independent files, and included into the main source.

target/%.adoc.epub: src/%.adoc tmp/book_cover.jpg
	asciidoctor-epub3 \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook

target/%.adoc.xml: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert DocBook to EPUB

# ------------------------------------------------
# With dbtoepub

# XXX TODO -- Add the cover image. There's no parameter to do it.

target/$(book_basename).adoc.xml.dbtoepub.epub: \
	target/$(book_basename).adoc.xml \
	src/$(book_basename)-docinfo.xml
	dbtoepub \
		--output $@ $<

# ------------------------------------------------
# With pandoc

target/$(book_basename).adoc.xml.pandoc.epub: \
	target/$(book_basename).adoc.xml \
	src/$(book_basename)-docinfo.xml \
	src/pandoc_epub_template.txt \
	src/pandoc_epub_stylesheet.css \
	tmp/book_cover.jpg
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=autor:$(book_author) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--epub-cover-image=tmp/book_cover.jpg \
		--output $@ $<

# ------------------------------------------------
# With xsltproc

%.adoc.xml.xsltproc.epub: %.adoc.xml tmp/book_cover.jpg
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
#	cp -f tmp/book_cover.jpg tmp/xsltproc/OEBPS/cover-image.jpg && \

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
#
#  cp -f src/xsltproc/stylesheet.css tmp/xsltproc/OEBPS/ && \

# ==============================================================
# Convert DocBook to OpenDocument

target/$(book_basename).adoc.xml.pandoc.odt: \
	target/$(book_basename).adoc.xml \
	src/$(book_basename)-docinfo.xml \
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
# Create the cover image

# ------------------------------------------------
# Create the canvas and texts of the cover image
 
tmp/book_cover.canvas.jpg:
	convert \
		-size 1200x1600 \
		canvas:khaki \
		$@

tmp/book_cover.title.jpg:
	convert \
		-background khaki \
		-font Helvetica \
		-pointsize 200 \
		-size 1200x \
		-gravity center \
		caption:$(title) \
		$@

tmp/book_cover.author.jpg:
	convert \
		-background khaki \
		-font Helvetica \
		-pointsize 90 \
		-size 1200x \
		-gravity center \
		caption:$(book_author) \
		$@

# ------------------------------------------------
# Create the cover image
 
tmp/book_cover.jpg: \
	tmp/book_cover.canvas.jpg \
	tmp/book_cover.title.jpg \
	tmp/book_cover.author.jpg \
	img/moravian_carst.jpg
	composite -gravity north -geometry +0+40 tmp/book_cover.title.jpg tmp/book_cover.canvas.jpg $@
	composite -gravity south -geometry +0+40 tmp/book_cover.author.jpg tmp/book_cover.jpg $@
	composite -gravity center img/moravian_carst.jpg tmp/book_cover.jpg $@

# ------------------------------------------------
# Convert the cover image to PDF

# This is needed in order to make sure the cover image ocuppies the whole page
# in the PDF versions of the book.

tmp/book_cover.pdf: tmp/book_cover.jpg
	img2pdf --output $@ --border 0 $<

# ==============================================================
# Change log

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
# formats that can include the cover image.
