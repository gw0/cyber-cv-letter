# cyber-cv-letter

A terminal/hacker-themed CV and cover-letter template, built to satisfy two readers at
once: a naive ATS text extractor and a human reviewer giving page one about six
seconds. Two authoring workflows — direct [Typst](https://typst.app) and
Markdown+[Pandoc](https://pandoc.org) — both compile to PDF through the same show-rule
mechanism (`src/markup.typ`), so they can't drift apart.

## Quick start

```sh
python3 -m venv .venv --without-pip
curl -sS https://bootstrap.pypa.io/get-pip.py | .venv/bin/python -
.venv/bin/python -m pip install pypandoc_binary pypdf pymupdf pillow
# then place a `typst` 0.14+ binary at .venv/bin/typst (see below)

make examples # renders the checked-in example PDFs (examples/{typst,markdown}/*.pdf)
make test     # builds examples/ (if needed) and runs the extraction verification suite
```

Typst has no PyPI package. This repo's own build downloaded the official prebuilt
binary from `github.com/typst/typst/releases` and copied it to `.venv/bin/typst`
directly (no sudo, no system install). Pandoc itself comes bundled with
`pypandoc_binary` — no separate install needed.

If your environment's pip fails with a permission error while loading its bundled
`cacert.pem` (a sandboxing quirk that treats `.pem` files as sensitive and redacts
them), install with `PIP_CERT=/etc/ssl/certs/ca-certificates.crt` and
`SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` set, and pass
`--use-deprecated=legacy-certs` to `pip install`.

## Content model

Both workflows author the same document shape; `examples/typst/cv.typ` and
`examples/markdown/cv.md` are the canonical reference. A few rules aren't
obvious from the examples alone:

- **Section headings** (`# ...`) must come from a closed vocabulary checked
  at compile time (`src/markup.typ`): `Summary`/`Professional Summary`,
  `Experience`/`Work Experience`/`Professional Experience`,
  `Projects`/`Personal Projects`/`Open Source Projects`,
  `Skills`/`Technical Skills`, `Education`, `Certifications`,
  `Publications`, `Languages`. Anything else fails the build with an
  `assert` error rather than rendering wrong — the fix is to rename the
  heading or add the new name to `section-vocabulary` deliberately.
- **An entry** is a `## Title | Date` heading immediately followed by an
  italic `Org | Location` line (optionally wrapping a logo image, e.g.
  `_[![](logos/x.png)] Cyberdyne Systems | Los Angeles, CA_`). The pairing
  is positional — the meta line has to come right after its heading, with
  nothing in between.
- **Skills** are a definition list (Markdown `Term\n: description`, Typst
  `/ Term: description`), rendered as one label+value line, never a table.
- A paragraph made of nothing but inline code (`` `PyTorch · vLLM · Triton` ``)
  renders as a muted tech-stack line under the entry it follows.
- The letter (`cv-letter`) takes a required `date` and has no section
  vocabulary or entry pairing — its body is plain paragraphs.

## Rendered examples

Three CV builds per workflow are checked into git next to their sources — chosen
to cover every visual feature between them rather than build the full flag
cartesian product. Regenerate them with `make examples` after a template change.

| File | Demonstrates |
|---|---|
| `cv.pdf` | Default: themed, green accent, A4, no logos/icons |
| `cv-plain.pdf` | `variant=plain` — no drawn marks, no accent colour |
| `cv-friggeri.pdf` | `accent=friggeri` + `accent-scope=first3` + `show-logos=true` + `show-icons=true` |

`letter.pdf` is also checked in per workflow. Any other flag combination
(`accent=red`, `paper-size=us-letter`, ...) is a one-liner away — see the flag
table below — but isn't committed as a separate file.

## Seeing the logo and icon features

Company logos on Experience entries and contact-line icons are real but **off by
default** (safest, most conventional path). `cv-friggeri.pdf` above already
shows both; to render them in isolation:

```sh
typst compile --font-path fonts --pdf-standard ua-1 \
  --input show-logos=true --input show-icons=true examples/typst/cv.typ cv-logos.pdf

# or, Markdown+Pandoc:
pandoc examples/markdown/cv.md -o cv-logos.pdf \
  --template=src/pandoc/template.typ --resource-path=examples/markdown \
  -V show-logos=true -V show-icons=true \
  --pdf-engine=.venv/bin/typst --pdf-engine-opt=--font-path=fonts \
  --pdf-engine-opt=--pdf-standard=ua-1 --pdf-engine-opt=--root=/ \
  -M root=$(pwd)
```

No content edit either way.

## One-flag variant surface

Every combination below is a flag, never a content edit:

| Flag | Values | Direct Typst | Markdown+Pandoc |
|---|---|---|---|
| Accent | `red` \| `green` \| `friggeri` | `--input accent=red` | `-V accent=red` |
| Accent scope | `full` \| `first3` | `--input accent-scope=first3` | `-V accent-scope=first3` |
| Variant | `themed` \| `plain` | `--input variant=plain` | `-V variant=plain` |
| Paper size | `a4` \| `us-letter` | `--input paper-size=us-letter` | `-V paper-size=us-letter` |
| Logos | `true` \| `false` | `--input show-logos=true` | `-V show-logos=true` |
| Icons | `true` \| `false` | `--input show-icons=true` | `-V show-icons=true` |
| Footer | `true` \| `false` | `--input show-footer=true` | `-V show-footer=true` |

`font`, `header-font`, and `margins` are also `cv-resume`/`cv-letter`
parameters, but aren't wired to a CLI flag in the examples above — change
them by editing the `.typ` source or `src/pandoc/*.typ` template directly.

## Package layout

```
lib.typ                  — package entrypoint (cv-resume, cv-letter)
src/
  tokens.typ              — palette, spacing scale, type scale, font-weight resolution
  marks.typ                — drawn chevron / block cursor / rule primitives
  markup.typ               — the entry-rendering mechanism — shared by both workflows
  resume.typ                — cv-resume(), shared header/footer components
  letter.typ                 — cv-letter()
  pandoc/template.typ         — CV pandoc --template target
  pandoc/letter-template.typ   — cover-letter pandoc --template target
fonts/IBM-Plex-{Mono,Sans}/     — default chrome/body families (SIL OFL, used by default)
fonts/{Roboto,SourceSansPro}/    — alternate families, not used by default
icons/fontawesome/                — optional contact-line icons
examples/typst/{cv,letter}.typ      — Sarah Connor example, direct Typst
examples/markdown/{cv,letter}.md     — same content, Markdown+Pandoc
examples/{typst,markdown}/*.pdf       — checked-in rendered examples: cv, cv-plain,
                                         cv-friggeri, letter (see above)
tests/extraction/                      — pypdf/pymupdf-based extraction verification
scripts/check_contrast.py               — WCAG contrast verification for every palette token
scripts/check_spacing.py                — verifies every spacing/indent token is a literal N * u
```

## Implementation notes

- **PDF/UA-1 is enforced at compile time on every build**
  (`--pdf-standard ua-1` on every Makefile target). Typst hard-fails on any
  image missing alt text under that flag, so the logo's `image()` call
  always carries `alt: <company name>`, derived from the same "Org |
  Location" text already on the line.
- The direct-Typst logo image path is root-relative
  (`/examples/typst/logos/cyberdyne.png`), not relative to the `.typ` file
  it's written in — `markup.typ` rebuilds the `image()` call (to attach alt
  text) from a different file, and a path relative to the *original* file
  wouldn't resolve from there.
- The contact-line icon paths in `resume.typ` are plain relative paths
  (`../icons/fontawesome/...`), not root-relative. A root-relative path
  resolves against different roots in the two workflows (project root for
  direct Typst's `--root .`, OS root for Pandoc's required `--root /`), so
  it can only work under one of them at a time; a path relative to
  `resume.typ`'s own on-disk location works under both.

## Known limitations

veraPDF validation, upload to independent ATS simulators, and a
screen-reader read-through haven't been done — PDF/UA-1 is targeted by
construction (compile-time enforcement above) rather than independently
verified against the full standard.
