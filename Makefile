# Makefile of _Krasina_

# By Marcos Cruz (programandala.net)
# http://ne.alinome.net

# Last modified 201904122001
# See change log at the end of the file

# ==============================================================
# Requirements

# - asciidoctor
# - asciidoctor-pdf
# - dbtoepub
# - pandoc
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
all: epub odt pdf

.PHONY: epub
epub: epubd epubp epubx

.PHONY: epubd
epubd: target/$(book_basename).adoc.xml.dbtoepub.epub

.PHONY: epubp
epubp: target/$(book_basename).adoc.xml.pandoc.epub

.PHONY: epubx
epubx: target/$(book_basename).adoc.xml.xsltproc.epub

.PHONY: odt
odt: target/$(book_basename).adoc.xml.pandoc.odt

.PHONY: pdf
pdf: pdfa4 pdfletter

.PHONY: pdfa4
pdfa4: target/$(book_basename).adoc.a4.pdf

.PHONY: pdfletter
pdfletter: target/$(book_basename).adoc.letter.pdf

.PHONY: xml
xml: target/$(book_basename).adoc.xml

.PHONY: clean
clean:
	rm -fr target/* tmp/*

# ==============================================================
# Convert Asciidoctor to PDF

target/%.adoc.a4.pdf: src/%.adoc
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc.letter.pdf: src/%.adoc
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook

target/%.adoc.xml: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert DocBook to EPUB

# ------------------------------------------------
# With dbtoepub

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
	src/pandoc_epub_stylesheet.css
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=autor:$(book_author) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--output $@ $<

# ------------------------------------------------
# With xsltproc

%.adoc.xml.xsltproc.epub: %.adoc.xml
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

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
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
# Change log

# 2019-03-24: Start.
#
# 2019-04-12: Add interface rules for OpenDocument and DocBook. Set `lang`.
# Consider DocBook a target instead of an intermediate format. Make the clean
# rule recursive.
