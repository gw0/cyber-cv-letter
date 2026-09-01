# cyber-cv-letter

A terminal/hacker-themed CV and cover-letter Typst package. One rendering
mechanism, two authoring workflows — hand-written `.typ` or Markdown via
Pandoc — so they can't drift apart. Built for two readers: a naive ATS
text-extractor (linear reading order, real text, nothing decorative in the
text stream) and a human reviewer giving page one about six seconds (bold
titles, scannable hierarchy, restrained color).

See `examples/typst/cv.pdf` and `examples/markdown/cv.pdf` for the
rendered output (built via `make examples`, see below).

## Repository layout note

`.github/` and `scripts/` are unavailable in this repository's current
development environment, so this repo uses `.github2/` and `scripts2/` in
their place. If you're working from a clone where the usual paths are
available, rename them back — `.github2/workflows/test.yml` won't run as
CI under any other path, since GitHub only picks up workflows under
`.github/workflows/`.

## Quick start (this repo's own examples and tests)

Everything lives under `.venv/`; nothing is installed system-wide.

```sh
make setup      # registers the local Typst package, vendors pandoc + typst into .venv/bin
make examples   # builds the 8-PDF example matrix (cv/cv-plain/cv-friggeri/letter x typst/markdown)
make test       # runs the contrast, spacing, and ATS-extraction checks
make thumbnails # renders cv/cv-plain/cv-friggeri/letter PNG previews into thumbnails/
```

`make setup` downloads a pinned `typst` release binary from GitHub and
installs the pinned Python dependencies from `requirements.txt` — both
require network access the first time.

## Writing your own CV

### Hand-written Typst

```typst
#import "@preview/cyber-cv-letter:0.1.0": cv

#show: cv.with(
  author: (
    name: "Sarah Connor",
    tagline: "AI Security Engineer",
    email: "sarah@example.com",
    location: "Fremont, CA",
    links: ("github.com/sconnor",),
  ),
)

= SUMMARY

...
```

See `examples/typst/cv.typ` and `examples/typst/letter.typ` for complete,
realistic reference documents.

### Markdown, via Pandoc

See `examples/markdown/cv.md` and `examples/markdown/letter.md` for
complete reference documents (front matter fields, section structure,
note-line and code-line syntax). One mechanism covers this repo's own
build and external use alike: a Pandoc ["defaults" file](https://pandoc.org/MANUAL.html#default-files)
(`pandoc/cv.yaml`, `pandoc/letter.yaml`) bundles the template path, the
`typst` pdf-engine, and every engine flag this package's markup contract
needs (package path, font path, PDF/UA-1 standard, and `--root=/` — see the
comment in `pandoc/cv.yaml` for why that's safe for this package
specifically) into one reusable file:

```sh
pandoc mycv.md -d path/to/cyber-cv-letter/pandoc/cv.yaml -o mycv.pdf
```

is the whole build, one command, no intermediate `.typ` file. This repo's
own `make examples` runs exactly this (see the Makefile), layering
per-variant `--input` values on top via repeated
`--pdf-engine-opt=--input --pdf-engine-opt=key=value` pairs.

- **This repo's own examples/tests** — fully local and offline, see *Quick
  start* above. `pandoc/cv.yaml`/`pandoc/letter.yaml` point `pdf-engine` and
  `--package-path` at this repo's own `.venv`/`.typst-packages`, and import
  `@local/cyber-cv-letter:0.1.0` from the template files.
- **External use, no local clone** — copy `pandoc/cv.yaml` (or
  `pandoc/letter.yaml`) and its neighboring `pandoc/cv-template.typ`
  alongside your own CV, and adjust `pdf-engine`/`--package-path` for your
  own environment (a system-installed `typst`, no `--package-path` at all).
  Once this package is published to Typst Universe, the template's own
  `#import "@preview/cyber-cv-letter:0.1.0"` line resolves automatically
  through Typst's own package-fetching, and `--package-path` drops out
  entirely.

Either way, Pandoc still needs the real `typst` CLI binary for
`--pdf-engine=typst` (the Python `typst` package is bindings-only, no CLI —
download the release binary from
[github.com/typst/typst/releases](https://github.com/typst/typst/releases)).

## Markup contract

| Source construct | Renders as |
|---|---|
| YAML front matter | Header block: name, tagline, contact line, links |
| `# SECTION` (H1) | Section header + rule + chevron |
| `## Title \| Date` (H2) | Entry title, date right-aligned in the section's accent color |
| Emph-only paragraph right after an H2 | Meta line (`Org \| Location`); a leading image becomes the entry logo |
| Plain paragraph(s) after the meta line | Tagline/body prose |
| Bullet list | Description bullets |
| `> note` right after a bullet | Note line — rendered only when `show-notes: true` |
| Trailing inline-code-only paragraph | Code line |
| Definition list | Skills row: one line per term, never a table/grid |

Section names are freeform — any `# SECTION` heading works, no fixed list
to match. *How* a section renders is decided entirely by the shape of its
content (does it contain H2 entries? is it all definition-list terms?
otherwise, freeform prose), never by its name.

## Parameters

Both `cv()` and `letter()` take: `author` (dict — `name`, `tagline`,
`email`, `location`, `phone`, `links`), `accent` (`"red"` (default),
`"green"`, `"friggeri"`, or a hex string/array), `accent-scope`
(`"full"` | `"first3"`), `variant` (`"themed"` | `"plain"`), `paper`
(`"a4"` | `"us-letter"`), `show-footer`, `show-icons`. `cv()` additionally
takes `show-logos`, `show-notes`. `letter()` additionally requires `date`.

## Accessibility

Targets PDF/UA-1 by construction (`--pdf-standard ua-1`), not independently
verified against the full standard. Decorative marks (chevron, cursor,
section rule, entry logos) are wrapped as PDF artifacts, excluded from the
accessibility tree. Every text-bearing color clears WCAG AA (4.5:1 against
white) — checked mechanically by `scripts2/check_contrast.py`.

## Verification

- `scripts2/check_contrast.py` — WCAG AA on every color token in
  `src/theme.typ`.
- `scripts2/check_spacing.py` — asserts every spacing token in
  `src/theme.typ` is a literal `N * u` multiple of the base unit.
- `scripts2/check_ats.py` — extraction acceptance checks against the built
  example PDFs, using two independent libraries (`pypdf`, `pymupdf`):
  linear reading order, this package's own example section names each on
  their own line and in order, intact contact strings, no decorative or
  private-use-area glyphs leaked into the text stream, and cross-workflow
  parity (the `.typ` example and the `.md` example extract identically).

Each has a `--all` CLI entry point for ad-hoc runs and pytest-discoverable
functions (`tests/test_*.py`) for CI — `make test` runs all three via
`pytest`.

## Known limitations

- No cross-page "keep together" grouping: a section header, or a skills
  row, can be split across a page boundary from its first entry/row.
- A published package can't add its own bundled fonts (IBM Plex Mono/Sans)
  to a consuming document's font search path — `--font-path` is a
  consumer-side compiler flag. Without those fonts installed system-wide,
  Typst falls back to automatic font substitution, not a build failure.
  This repo's own dev/CI build passes `--font-path fonts` explicitly and is
  unaffected.

## License

AGPL-3.0-or-later — see `LICENSE.txt`. Bundled fonts (`fonts/`) and icons
(`icons/`) carry their own licenses in the same directories.
