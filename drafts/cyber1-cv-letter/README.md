# cyber-cv-letter

A terminal/hacker-themed CV and cover-letter template, built to satisfy two readers at
once: a naive ATS text extractor and a human reviewer giving page one about six
seconds. Two authoring workflows — direct [Typst](https://typst.app) and
Markdown+[Pandoc](https://pandoc.org) — both compile to PDF through the same show-rule
mechanism, so they can't drift apart. Full spec: `specs/20260828-mvp.md` (supersedes
`specs/20260821-design-cyber.md` and `specs/20260821-rev-modern-cv.md`, both still
useful background).

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
default** (safest, most conventional path — decision 13 in the spec).
`cv-friggeri.pdf` above already shows both; to render them in isolation:

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

Every combination below is a flag, never a content edit (spec §9.3):

| Flag | Values | Direct Typst | Markdown+Pandoc |
|---|---|---|---|
| Accent | `red` \| `green` \| `friggeri` | `--input accent=red` | `-V accent=red` |
| Accent scope | `full` \| `first3` | `--input accent-scope=first3` | `-V accent-scope=first3` |
| Variant | `themed` \| `plain` | `--input variant=plain` | `-V variant=plain` |
| Paper size | `a4` \| `us-letter` | `--input paper-size=us-letter` | `-V paper-size=us-letter` |
| Logos | `true` \| `false` | `--input show-logos=true` | `-V show-logos=true` |
| Icons | `true` \| `false` | `--input show-icons=true` | `-V show-icons=true` |
| Footer | `true` \| `false` | `--input show-footer=true` | `-V show-footer=true` |

## Package layout

```
lib.typ                  — package entrypoint (cv-resume, cv-letter)
src/
  tokens.typ              — palette, spacing scale, type scale, font-weight resolution
  marks.typ                — drawn chevron / block cursor / rule primitives
  markup.typ               — the entry-rendering mechanism (§11) — shared by both workflows
  resume.typ                — cv-resume(), shared header/footer components
  letter.typ                 — cv-letter()
  pandoc/template.typ         — CV pandoc --template target
  pandoc/letter-template.typ   — cover-letter pandoc --template target
fonts/IBM-Plex-{Mono,Sans}/     — default chrome/body families (SIL OFL)
fonts/{Roboto,SourceSansPro}/    — alternate families (existing, kept)
icons/fontawesome/                — optional contact-line icons
examples/typst/{cv,letter}.typ      — Sarah Connor example, direct Typst
examples/markdown/{cv,letter}.md     — same content, Markdown+Pandoc
examples/{typst,markdown}/*.pdf       — checked-in rendered examples: cv, cv-plain,
                                         cv-friggeri, letter (see above)
tests/extraction/                      — pypdf/pymupdf-based extraction verification
scripts/check_contrast.py               — WCAG contrast verification for every palette token
```

## Deliberate deviations from the spec worth flagging

- **PDF/UA-1 is enforced at compile time everywhere** (`--pdf-standard ua-1` on
  every Makefile target), not just "targeted by construction." The MVP spec's
  original decision 8 was "no alt text on the logo image, by explicit
  instruction" — but Typst's `--pdf-standard ua-1` hard-fails on any image
  missing alt text, so shipping that decision literally would mean the
  `show-logos: true` build could never compile under the strict flag. Per an
  explicit override during implementation, the logo's `image()` call now
  carries `alt: <company name>` (derived from the same "Org | Location" text
  already on the line, not hand-authored), and every build — not just the
  default — compiles under the full standard.
- The direct-Typst logo image path is root-relative
  (`/examples/typst/logos/cyberdyne.png`), not relative to the `.typ` file it's
  written in. `markup.typ` rebuilds the `image()` call (to attach alt text) from
  a different file, and a path relative to the *original* file wouldn't resolve
  from there.
- The contact-line icon paths in `resume.typ` are plain relative paths
  (`../icons/fontawesome/...`), not root-relative. A root-relative path resolves
  against different roots in the two workflows (project root for direct Typst's
  `--root .`, OS root for Pandoc's required `--root /`), so it can only work
  under one of them at a time; a path relative to `resume.typ`'s own on-disk
  location works under both.

## Known limitations (deferred, not forgotten — see spec §1)

veraPDF validation, upload to independent ATS simulators, and a screen-reader
read-through are all out of scope for this MVP and listed as explicit follow-ups
in the spec, not silently dropped.
