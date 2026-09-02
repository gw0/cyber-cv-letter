// Design tokens: palette, accent presets, spacing, page geometry, font weights.
// No type-scale dict here — each visual role's (font, weight, size) is a
// literal at its one owning call site (see entries.typ / cv.typ).

#let bg = rgb("#ffffff")
#let fg = rgb("#3c3836")
#let muted = rgb("#7c6f64")

#let accent-presets = (
  red: (rgb("#af3a03"),),
  green: (rgb("#157d00"),),
  gray: (rgb("#3c3836"),), // matches `fg` above — grayscale-safe accent for the plain-style build
  friggeri: (
    rgb("#008194"), rgb("#df0c3d"), rgb("#ad6000"), rgb("#628000"), rgb("#a133fa"),
  ),
)

// Resolves any accepted accent value to a list of colors, so a single-color
// preset and a multi-color rotation share one code path.
#let resolve-accent(value) = {
  if type(value) == str {
    if value in accent-presets {
      accent-presets.at(value)
    } else {
      (rgb(value),)
    }
  } else if type(value) == array {
    value.map(v => if type(v) == str { rgb(v) } else { v })
  } else {
    (value,)
  }
}

// Shared rotation/lookup used by section headers, entry dates, and the
// skills-row label.
#let accent-at(accent-list, index) = accent-list.at(calc.rem(calc.max(index, 0), accent-list.len()))

// One base spacing unit; values verified against real rendered PDFs
// (see specs/20260902-simplify.md).
#let u = 6.4pt

#let space-paragraph = 1.25 * u // ambient bare-paragraph gap; also the gap below a whole bullet list (see entries.typ's list-rule)
#let space-letter-paragraph = 2 * u // letter-only paragraph gap
#let space-bullet = 1 * u
#let space-entry = 2 * u
#let space-section-to-rule = 0.625 * u
#let space-rule-to-content = 1.25 * u // section rule to what follows it; at least space-paragraph
#let space-header-to-section = 3 * u // above every section header, including the first
#let space-header-line = 1 * u // line-to-line within the identity block; reused for entry title<->meta
#let body-indent = 1 * u
#let space-code-indent = 1.65 * u // code-line indent; lines the code line up with bullet text (body-indent plus the bullet marker's own width, 10.56pt — a constant here so it can't resolve against whatever ambient style the matching show rule happens to inherit)

// IBM Plex ships Medium/SemiBold as distinct font families (confirmed via
// each .ttf's own name table), not weight variants of the base family —
// requesting weight: "medium" on the base family would silently substitute
// the nearest weight Typst can find.
#let font-weight-families = (
  "IBM Plex Mono": (medium: "IBM Plex Mono Medm", semibold: "IBM Plex Mono SmBld"),
  "IBM Plex Sans": (medium: "IBM Plex Sans Medm", semibold: "IBM Plex Sans SmBld"),
)

// Returns a dict spreadable directly into text(..): text(..resolve-font(...)).
#let resolve-font(family, weight: "regular") = {
  let special = font-weight-families.at(family, default: (:))
  if weight in special {
    (font: special.at(weight), weight: "regular")
  } else {
    (font: family, weight: weight)
  }
}

#let page-geometry = (
  a4: (paper: "a4", margin: (top: 16mm, bottom: 16mm, left: 24mm, right: 18mm)),
  us-letter: (paper: "us-letter", margin: (top: 16mm, bottom: 16mm, left: 25mm, right: 19mm)),
)

// Horizontal offset of the marks drawn outside the text column (chevrons).
#let mark-gutter = 4 * u

// Entry logo cell, when show-logos: true. Fixed multiples of the base unit,
// not em — an em here would resolve against whatever ambient text size the
// referencing show rule happens to inherit. 6:4 keeps the 3:2 landscape
// ratio of the cell the logos were cropped for.
#let logo-width = 6 * u
#let logo-height = 4 * u
#let logo-gutter = 1.75 * u
#let logo-column = logo-width + logo-gutter

// Size of a code line / inline code span. Unlike every other type size in
// this package, which is a literal at its one owning call site, this one is
// a token because two places must agree on it: cv()'s `show raw: set
// text(...)`, and the paragraph-rule test that recognises a code line by the
// ambient that show-set leaves behind (see entries.typ).
#let size-code = 9pt

// Width of the skills label column, in characters of the monospace chrome
// font. A fixed column rather than a per-section max over the labels: the
// max needs every sibling row's label before any row can be drawn, which is
// the one thing a per-item show rule cannot see.
#let skills-label-chars = 12
