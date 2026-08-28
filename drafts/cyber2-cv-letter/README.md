# cyber-cv-letter

A single-column, ATS-friendly, visually distinctive Typst package for
software-engineering CVs and cover letters. Implements the visual design
system in `specs/20260821-design-cyber.md` and the structural contract in
`specs/20260828-mvp.md`.

Every design decision here is judged against two readers at once:

- **A naive ATS text-extractor** — linear, single-column, real text,
  closed section-name vocabulary, nothing decorative in the text stream.
- **A human reviewer giving page one about 6 seconds** — bold job titles,
  quantified outcomes above the fold, whitespace, scannable hierarchy.

See `scripts/ats_check.py` for the automated version of the first check,
and the rendered examples under `examples/` for the second.

## Quickstart

```sh
python3 -m venv --without-pip .venv   # or plain `python3 -m venv .venv` if
                                       # your platform's venv can bootstrap
                                       # pip on its own
curl -sS https://bootstrap.pypa.io/get-pip.py | .venv/bin/python3 -
.venv/bin/python3 -m pip install -r requirements.txt

# Pandoc ships as a bundled binary inside pypandoc_binary; put it on PATH:
ln -s "$(.venv/bin/python3 -c 'import pypandoc; print(pypandoc.get_pandoc_path())')" .venv/bin/pandoc

# The Typst *compiler* is a separate CLI download — Pandoc's
# --pdf-engine=typst shells out to a real binary, never a Python module,
# so the pip `typst` package (Python bindings only) isn't installed here.
# Pinned per mvp spec §12/§9.4 — treat an upgrade as a change requiring a
# full re-verification pass.
curl -sSL -o /tmp/typst.tar.xz \
  https://github.com/typst/typst/releases/download/v0.15.1/typst-x86_64-unknown-linux-musl.tar.xz
tar -xf /tmp/typst.tar.xz -C /tmp
cp /tmp/typst-x86_64-unknown-linux-musl/typst .venv/bin/typst
chmod +x .venv/bin/typst
# (macOS/Windows: grab the matching release asset from
# https://github.com/typst/typst/releases/tag/v0.15.1 instead.)

# Register this repo as a local Typst package, so both the hand-authored
# .typ examples and template/*.typ can `#import "@local/hacker-cv:0.1.0"`
# instead of a fragile "/lib.typ" path (see "Why a local package" below):
mkdir -p ~/.local/share/typst/packages/local/hacker-cv
ln -s "$PWD" ~/.local/share/typst/packages/local/hacker-cv/0.1.0
# (macOS: ~/Library/Application Support/typst/packages/local/...; Windows:
# %APPDATA%\typst\packages\local\...; see Typst's own package docs.)

export PATH="$PWD/.venv/bin:$PATH"
```

All build commands below assume `.venv/bin` is on `PATH` and are run **from
the repo root** — both matter: Pandoc resolves the Markdown examples'
relative logo-image references against its own working directory, not
against the Markdown source file's location.

```sh
# Hand-authored Typst -> PDF, directly, no Pandoc involved:
typst compile examples/typst/cv.typ examples/typst/cv.pdf --font-path fonts --pdf-standard ua-1
typst compile examples/typst/cv.typ examples/typst/cv-plain.pdf --font-path fonts --pdf-standard ua-1 --input variant=plain
typst compile examples/typst/letter.typ examples/typst/letter.pdf --font-path fonts --pdf-standard ua-1

# Markdown -> Pandoc (typst writer, template/*.typ) -> Typst -> PDF, one command:
pandoc examples/markdown/cv.md -d template/pandoc-cv.yaml -o examples/markdown/cv.pdf

pandoc examples/markdown/cv.md -d template/pandoc-cv.yaml \
  --pdf-engine-opt=--input --pdf-engine-opt=variant=plain \
  -o examples/markdown/cv-plain.pdf

pandoc examples/markdown/cv.md -d template/pandoc-cv.yaml \
  --pdf-engine-opt=--input --pdf-engine-opt=accent=friggeri \
  --pdf-engine-opt=--input --pdf-engine-opt=accent-scope=first3 \
  --pdf-engine-opt=--input --pdf-engine-opt=icons=true \
  --pdf-engine-opt=--input --pdf-engine-opt=logos=true \
  -o examples/markdown/cv-friggeri.pdf

# Plain-text build (Markdown source only — a hand-authored .typ has no
# Markdown to run through Pandoc's plain writer):
pandoc examples/markdown/cv.md -f markdown-blank_before_blockquote -t plain --standalone \
  --template=template/cv.txt -o examples/markdown/cv.txt

pandoc examples/markdown/letter.md -d template/pandoc-letter.yaml -o examples/markdown/letter.pdf

# Automated ATS acceptance check (two independent extractors: pypdf, pymupdf):
.venv/bin/python3 scripts/ats_check.py --all
```

Every example already clears PDF/UA-1 (`--pdf-standard ua-1`), so the flag
above is simply always on. A UA-1 error on new content is a genuine
accessibility gap to fix (missing alt text, bad heading structure, ...) —
dropping the flag is a documented manual last resort, not a default
fallback.

## Why a local package

Pandoc, when using `--pdf-engine=typst`, generates the substituted Typst
source into a temp file and invokes `typst compile` on it directly — the
compiled entry file's real location is Pandoc's choice, not
`template/cv.typ`'s own path. A plain relative import (`"lib.typ"`) would
resolve against wherever that temp file happens to sit, not this repo. A
package-absolute import (`@local/hacker-cv:0.1.0`) sidesteps this
entirely: `src/*.typ` resolves its own absolute paths (e.g.
`icons.typ`'s icon files) against the *package's* root regardless of
where the compiled entry file physically ends up, with no `--root` flag
needed anywhere.

## Package structure

```
typst.toml              package manifest (MIT; bundled fonts keep their own SIL OFL notices)
lib.typ                 single entrypoint, re-exports cv() and cover-letter()

src/
  theme.typ             design tokens: palette, accent presets, spacing/type scale, page geometry
  fonts.typ             font-chrome / font-body pass-through (see §8 below)
  layout.typ            page setup, header block, section/entry rendering engine
  letter.typ            cover-letter template
  icons.typ             icon loading + filename-derived alt text
  ats.typ               pdf.artifact wrapping, PDF metadata setup

template/
  cv.typ                Pandoc --template skeleton for a CV: imports the package, wires
                         identity fields + config into cv(), then emits $body$
  letter.typ             same shape for cover-letter()
  cv.txt                 plain-text --template skeleton (name/tagline/contact + $body$)
  pandoc-cv.yaml         Pandoc defaults file: from/to/template/pdf-engine/pdf-engine-opts
  pandoc-letter.yaml      same, targeting letter.typ

fonts/IBMPlexMono/, fonts/IBMPlexSans/    default font-chrome / font-body (downloaded, SIL OFL)
fonts/SourceSansPro/, fonts/Roboto/       alternate families, already bundled

icons/fontawesome/       contact-field icons, renamed to semantic keys (email.png, phone.png, ...)

examples/
  typst/                 hand-authored .typ content — cv.typ (+ cv.pdf, cv-plain.pdf),
                          letter.typ (+ letter.pdf)
  markdown/               equivalent pure-content .md — cv.md (+ cv.pdf, cv-plain.pdf,
                          cv-friggeri.pdf, cv.txt, logos/), letter.md (+ letter.pdf) —
                          visually indistinguishable from examples/typst

scripts/
  ats_check.py           automated ATS-style extraction acceptance check
```

`template/` is **not** wired to Typst's own `[template]` / `typst init`
manifest mechanism — these files are full of Pandoc's `$var$`/`$if$`
syntax and aren't valid standalone Typst, so they couldn't serve that
purpose. `examples/typst/cv.typ` is the "here's how you use this package
directly" reference instead.

## Markup convention

Entries are plain Markdown/Typst markup — never a function call. This is
what lets the same content work unchanged through both the hand-authored
Typst workflow and the Markdown-via-Pandoc workflow:

| Source construct | Renders as |
|---|---|
| YAML front matter | Header block (name, tagline, contact, links) |
| `# SECTION` (H1) | Section header + drawn rule + chevron — closed vocabulary only, build fails otherwise |
| `## Title \| Date` (H2) | Entry title + right-pushed date |
| Emph-only paragraph right after the H2 | Meta line (`Org \| Location`); a leading `![](path)` becomes the entry logo |
| Plain paragraph after the meta line | Tagline |
| Bullet list | Description bullets |
| `> comment` right after a bullet (blockquote) | Master-CV comment — rendered only when `master: true` |
| Trailing inline-code paragraph | Per-role tech line |
| Definition list (`Term` / `: values`) | Skills row — one line, never a table |

Full contract: `specs/20260828-mvp.md` §5.

Logo image references in Markdown content are written **repo-root-relative,
without a leading slash** (e.g. `![](examples/markdown/logos/cyberdyne.png)`,
not `/examples/markdown/logos/cyberdyne.png`) — Pandoc's own PDF-production
step fetches every referenced image itself, before Typst ever runs, and
treats a leading `/` as an OS-filesystem-absolute path rather than a
project-root path, silently dropping the image on failure. A bare relative
path, resolved against Pandoc's working directory (the repo root, per the
"run from the repo root" note above), is what survives that step; the
library normalizes it to a package-absolute path internally when
re-embedding it for the logo/alt-text box.

## Configuration

Set via the template call (`#show: cv.with(...)` in Typst, or YAML front
matter through the Markdown/Pandoc path):

| Parameter | Type | Default |
|---|---|---|
| `paper` | `"a4"` \| `"us-letter"` | `"a4"` |
| `accent` | `"green"` \| `"red"` \| `"friggeri"` \| hex | `"green"` |
| `accent-scope` | `"full"` \| `"first3"` | `"full"` |
| `font-chrome` | family name | `"IBM Plex Mono"` |
| `font-body` | family name | `"IBM Plex Sans"` |
| `icons` | bool | `false` |
| `logos` | bool | `false` |
| `master` | bool | `false` |

`font-chrome`/`font-body` accept any family under `fonts/<Family>/`
(`IBM Plex Mono`, `IBM Plex Sans`, `Roboto`, `Source Sans Pro` are bundled)
or a system-installed family name — Typst's normal font-resolution
fallback, no special-casing needed. `Roboto`/`Source Sans Pro` work with
zero downloads; note Roboto is not a true monospace, so using it for
`font-chrome` is a documented approximation.

`accent`/`accent-scope`/`icons`/`logos` are the only fields a build-time
preset (e.g. the `friggeri` variant above) ever overrides, so
`template/cv.typ` reads them from Typst's `sys.inputs` first
(`--pdf-engine-opt=--input --pdf-engine-opt=<key>=<value>`), falling back
to the Markdown front-matter value. `plain` (`variant=plain`, also
`sys.inputs`) strips accent/motifs to black text and plain rules —
identical structure and content, never a separate content fork.

## Verification

- `.venv/bin/python3 scripts/ats_check.py --all` — linear reading order, closed-vocabulary
  section names each on their own line, intact contact strings, no
  private-use-area/replacement glyphs, no banned decorative characters.
- Cross-workflow parity: `examples/typst/cv.pdf` and
  `examples/markdown/cv.pdf` extract to byte-identical text (verified) and
  are visually indistinguishable.
- Identity fields (`name`/`tagline`/`email`/`phone`/`location`) containing
  `@`, `&`, `+`, `,` render with no stray backslashes in the
  Markdown-sourced outputs — verified by spot-checking extracted text.
  These fields are passed to `cv()`/`cover-letter()` as Typst content
  (`[$email$]`) rather than a quoted string: Pandoc's typst writer escapes
  Typst-special characters (`@ # _ * ...`) when rendering text as markup,
  and that escaping is only meaningful in markup, not inside a quoted
  string literal's more limited escape grammar. The library flattens
  these back to plain text internally (`flatten-text()`), so hand-authored
  `.typ` callers passing plain strings are unaffected.

## Known limitations

- A section header can be orphaned at the bottom of a page with its first
  entry pushed to the next page (no cross-block "stay together" grouping
  across separate render calls yet). Cosmetic, not an ATS or content
  issue; worth revisiting if it recurs on real content.
- The `txt` build variant only applies to Markdown sources — a
  hand-authored `.typ` file has no Markdown to run through Pandoc's plain
  writer.
- `accent` as an arbitrary custom hex list (beyond the built-in `friggeri`
  rotation) is supported by `theme.typ` but not exercised by an example.
