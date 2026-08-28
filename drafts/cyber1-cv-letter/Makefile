# Build pipeline — spec/20260828-mvp.md §10.
#
# Two workflows (typst = direct Typst, markdown = Markdown+Pandoc) x three CV
# builds, chosen to cover every visual feature between them rather than the
# full flag cartesian product:
#   cv.pdf          — default: themed, green accent, a4, no logos/icons
#   cv-plain.pdf     — variant=plain (no drawn marks, no accent colour)
#   cv-friggeri.pdf   — friggeri accent rotation + first3 scope + logos + icons
# Plus one letter build per workflow. All eight PDFs render straight into
# examples/{typst,markdown}/ and are committed there — no separate dist/
# staging directory to keep in sync (spec §9.3's flag surface still applies
# to any combination not shown here; see README's flag table).

TYPST := .venv/bin/typst
PANDOC := .venv/lib/python3.13/site-packages/pypandoc/files/pandoc
PYTHON := .venv/bin/python
FONT_PATH := fonts
ROOT := $(CURDIR)

TYPST_LIB := lib.typ $(wildcard src/*.typ) $(wildcard src/pandoc/*.typ)

# --pdf-standard ua-1: strict PDF/UA-1 conformance on every build, every
# image (including the optional logo) must carry alt text — see README for
# why this MVP deviates from the design-cyber spec's "no alt text" default.
TYPST_FLAGS := --root . --font-path $(FONT_PATH) --pdf-standard ua-1

# --pdf-engine-opt --root / : Pandoc extracts referenced images (the logo)
# to an OS-absolute temp path and writes that absolute path into the
# generated Typst source. Typst treats a leading "/" as project-root-
# relative, never as a true OS-absolute path — so root must be the OS root
# for that path to resolve, and this package's own sources are then
# imported through the same anchor via the "root" -M variable
# (src/pandoc/template.typ, src/pandoc/letter-template.typ).
PANDOC_ENGINE_FLAGS := \
	--pdf-engine=$(TYPST) \
	--pdf-engine-opt=--font-path=$(FONT_PATH) \
	--pdf-engine-opt=--pdf-standard=ua-1 \
	--pdf-engine-opt=--root=/ \
	-M root=$(ROOT)

.PHONY: all examples test

all: examples

examples: \
	examples/typst/cv.pdf examples/typst/cv-plain.pdf examples/typst/cv-friggeri.pdf \
	examples/typst/letter.pdf \
	examples/markdown/cv.pdf examples/markdown/cv-plain.pdf examples/markdown/cv-friggeri.pdf \
	examples/markdown/letter.pdf
	@echo "Rendered examples up to date."

# ---- Direct Typst workflow ----

examples/typst/cv.pdf: examples/typst/cv.typ $(TYPST_LIB)
	$(TYPST) compile $(TYPST_FLAGS) $< $@

examples/typst/cv-plain.pdf: examples/typst/cv.typ $(TYPST_LIB)
	$(TYPST) compile $(TYPST_FLAGS) --input variant=plain $< $@

examples/typst/cv-friggeri.pdf: examples/typst/cv.typ $(TYPST_LIB)
	$(TYPST) compile $(TYPST_FLAGS) \
		--input accent=friggeri --input accent-scope=first3 \
		--input show-logos=true --input show-icons=true $< $@

examples/typst/letter.pdf: examples/typst/letter.typ $(TYPST_LIB)
	$(TYPST) compile $(TYPST_FLAGS) $< $@

# ---- Markdown + Pandoc workflow ----

examples/markdown/cv.pdf: examples/markdown/cv.md $(TYPST_LIB)
	$(PANDOC) $< -o $@ --template=src/pandoc/template.typ \
		--resource-path=examples/markdown $(PANDOC_ENGINE_FLAGS)

examples/markdown/cv-plain.pdf: examples/markdown/cv.md $(TYPST_LIB)
	$(PANDOC) $< -o $@ --template=src/pandoc/template.typ \
		--resource-path=examples/markdown $(PANDOC_ENGINE_FLAGS) -V variant=plain

examples/markdown/cv-friggeri.pdf: examples/markdown/cv.md $(TYPST_LIB)
	$(PANDOC) $< -o $@ --template=src/pandoc/template.typ \
		--resource-path=examples/markdown $(PANDOC_ENGINE_FLAGS) \
		-V accent=friggeri -V accent-scope=first3 -V show-logos=true -V show-icons=true

examples/markdown/letter.pdf: examples/markdown/letter.md $(TYPST_LIB)
	$(PANDOC) $< -o $@ --template=src/pandoc/letter-template.typ \
		--resource-path=examples/markdown $(PANDOC_ENGINE_FLAGS)

# ---- Verification (Python venv: pypdf + pymupdf) ----
# No veraPDF target in this MVP (§1, §9) — PDF/UA-1 is targeted by
# construction and enforced at compile time via --pdf-standard ua-1 above,
# not independently verified against the full standard.

test: examples
	$(PYTHON) tests/extraction/test_extraction.py
