.PHONY: all setup examples test thumbnails clean

TYPST_VERSION := 0.15.1
TYPST_ARCHIVE := typst-x86_64-unknown-linux-musl

TYPST := .venv/bin/typst
PANDOC := .venv/bin/pandoc
PYTHON := .venv/bin/python3
PYLIBS := .venv/pylibs

export PYTHONPATH := $(PYLIBS)

TYPST_FLAGS := --package-path .typst-packages --font-path fonts --pdf-standard ua-1
TYPST_PNG_FLAGS := --package-path .typst-packages --font-path fonts

# Every package source file — a prerequisite of each example PDF below, so
# editing the package itself (not just the example content) triggers a
# rebuild.
PKG_SOURCES := lib.typ typst.toml $(wildcard src/*.typ)
PANDOC_CV_SOURCES := pandoc/cv-template.typ pandoc/cv.yaml
PANDOC_LETTER_SOURCES := pandoc/letter-template.typ pandoc/letter.yaml

all: examples test

# ---------------------------------------------------------------------------
# setup — local package registration + vendored pandoc/typst binaries.
# Nothing installed system-wide; everything lives under .venv/.
# ---------------------------------------------------------------------------

setup: .typst-packages/local/cyber-cv-letter/0.1.0 $(PANDOC) $(TYPST)

.typst-packages/local/cyber-cv-letter/0.1.0:
	mkdir -p .typst-packages/local/cyber-cv-letter
	ln -sfn "$(CURDIR)" $@

$(PYLIBS)/.install-stamp: requirements.txt
	mkdir -p $(PYLIBS)
	pip install --target=$(PYLIBS) -r requirements.txt
	touch $@

$(PANDOC): $(PYLIBS)/.install-stamp
	mkdir -p .venv/bin
	ln -sf "$(CURDIR)/$(PYLIBS)/pypandoc/files/pandoc" $(PANDOC)

$(TYPST):
	mkdir -p .venv/bin
	curl -sL "https://github.com/typst/typst/releases/download/v$(TYPST_VERSION)/$(TYPST_ARCHIVE).tar.xz" -o "$(TMPDIR)/typst.tar.xz"
	tar -xJf "$(TMPDIR)/typst.tar.xz" -C "$(TMPDIR)"
	cp "$(TMPDIR)/$(TYPST_ARCHIVE)/typst" $(TYPST)
	chmod +x $(TYPST)

# ---------------------------------------------------------------------------
# examples — the 8-PDF matrix: {cv,cv-plain,cv-friggeri,letter} x
# {typst,markdown}. Literal dependency rules, not a flag cartesian product.
# The markdown workflow is a single Pandoc invocation per PDF (`pandoc ... -d
# pandoc/cv.yaml -o file.pdf`, --pdf-engine-opt flags layered on top for the
# per-variant --input values) — no intermediate .typ file. See pandoc/cv.yaml
# for why --root=/ in that defaults file makes this package's single-step
# build safe (unlike a naive --pdf-engine=typst call against a package that
# reconstructs image() calls inside an imported package file).
# ---------------------------------------------------------------------------

# Turns a list of "key=value" pairs into repeated
# "--pdf-engine-opt=--input --pdf-engine-opt=key=value" flags, so Pandoc's
# defaults-file pdf-engine-opts (package-path/font-path/pdf-standard/root)
# and these per-variant --input values both reach the same `typst` process.
pandoc_inputs = $(foreach kv,$(1),--pdf-engine-opt=--input --pdf-engine-opt=$(kv))

FRIGGERI_INPUTS := accent=friggeri accent-scope=first3 show-logos=true show-notes=true
FRIGGERI_FLAGS := $(foreach kv,$(FRIGGERI_INPUTS),--input $(kv))
PLAIN_INPUTS := accent=gray show-icons=false show-footer=false
PLAIN_FLAGS := $(foreach kv,$(PLAIN_INPUTS),--input $(kv))

examples: setup \
	examples/typst/cv.pdf examples/typst/cv-plain.pdf examples/typst/cv-friggeri.pdf examples/typst/letter.pdf \
	examples/markdown/cv.pdf examples/markdown/cv-plain.pdf examples/markdown/cv-friggeri.pdf examples/markdown/letter.pdf

examples/typst/cv.pdf: examples/typst/cv.typ $(PKG_SOURCES)
	$(TYPST) compile $< $@ $(TYPST_FLAGS)

examples/typst/cv-plain.pdf: examples/typst/cv.typ $(PKG_SOURCES)
	$(TYPST) compile $< $@ $(TYPST_FLAGS) $(PLAIN_FLAGS)

examples/typst/cv-friggeri.pdf: examples/typst/cv.typ $(PKG_SOURCES)
	$(TYPST) compile $< $@ $(TYPST_FLAGS) $(FRIGGERI_FLAGS)

examples/typst/letter.pdf: examples/typst/letter.typ $(PKG_SOURCES)
	$(TYPST) compile $< $@ $(TYPST_FLAGS)

examples/markdown/cv.pdf: examples/markdown/cv.md $(PANDOC_CV_SOURCES) $(PKG_SOURCES)
	$(PANDOC) $< -d pandoc/cv.yaml -o $@

examples/markdown/cv-plain.pdf: examples/markdown/cv.md $(PANDOC_CV_SOURCES) $(PKG_SOURCES)
	$(PANDOC) $< -d pandoc/cv.yaml $(call pandoc_inputs,$(PLAIN_INPUTS)) -o $@

examples/markdown/cv-friggeri.pdf: examples/markdown/cv.md $(PANDOC_CV_SOURCES) $(PKG_SOURCES)
	$(PANDOC) $< -d pandoc/cv.yaml $(call pandoc_inputs,$(FRIGGERI_INPUTS)) -o $@

examples/markdown/letter.pdf: examples/markdown/letter.md $(PANDOC_LETTER_SOURCES) $(PKG_SOURCES)
	$(PANDOC) $< -d pandoc/letter.yaml -o $@

# ---------------------------------------------------------------------------
# test — contrast + spacing + ATS-extraction + rendered-layout checks, all
# wired into one target so nothing is left unwired. The layout check compares
# every text span's position against tests/layout_baseline.json; when a
# change to the rendering is intended, review the PDFs and then regenerate it
# with `python3 tests/check_layout.py --update`.
#
# Each check is one file that is both a `--all` CLI and a set of pytest
# functions; pytest.ini points collection at tests/ and widens the filename
# glob to check_*.py, so no wrapper files are needed.
# ---------------------------------------------------------------------------

test: examples
	$(PYTHON) -m pytest -q

thumbnails: examples
	mkdir -p thumbnails
	$(TYPST) compile examples/typst/cv.typ thumbnails/cv.png $(TYPST_PNG_FLAGS) --format png --ppi 150 --pages 1
	$(TYPST) compile examples/typst/cv.typ thumbnails/cv-plain.png $(TYPST_PNG_FLAGS) $(PLAIN_FLAGS) --format png --ppi 150 --pages 1
	$(TYPST) compile examples/typst/cv.typ thumbnails/cv-friggeri.png $(TYPST_PNG_FLAGS) $(FRIGGERI_FLAGS) --format png --ppi 150 --pages 1
	$(TYPST) compile examples/typst/letter.typ thumbnails/letter.png $(TYPST_PNG_FLAGS) --format png --ppi 150 --pages 1

clean:
	rm -f examples/typst/*.pdf examples/markdown/*.pdf thumbnails/*.png
