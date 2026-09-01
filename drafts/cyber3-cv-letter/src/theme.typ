// Design tokens: palette, accent presets, spacing, page geometry, font weights.
// No type-scale dict here — each visual role's (font, weight, size) is a
// literal at its one owning call site (see entries.typ / cv.typ).

#let bg = rgb("#ffffff")
#let fg = rgb("#3c3836")
#let muted = rgb("#7c6f64")
#let secondary = rgb("#076678")
#let note-tint = muted

#let accent-presets = (
  red: (rgb("#af3a03"),),
  green: (rgb("#157d00"),),
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

// Color for the given 0-based section index, wrapping around the list —
// the shared rotation/lookup used by section headers, entry dates, and the
// skills-row label.
#let accent-at(accent-list, index) = accent-list.at(calc.rem(calc.max(index, 0), accent-list.len()))

// One base spacing unit. Starting point carried over from prior prototyping;
// re-verify empirically once rendered — pixel measurements don't
// automatically transfer across a mechanism change.
#let u = 6.4pt

#let space-paragraph = 1.25 * u // ambient bare-paragraph gap; also the gap around a whole bullet list (list has no separate above/below, so it inherits ambient par.spacing)
#let space-bullet = 1 * u // bullet-to-bullet within one list
#let space-entry = 2 * u // entry-to-entry
#let space-section-to-rule = 0.625 * u // section-heading text to its rule
#let space-rule-to-content = 1.25 * u // section rule to what follows it; at least space-paragraph
#let space-header-to-section = 3 * u // above every section header, including the first
#let space-header-line = 1 * u // line-to-line within the identity block; reused for entry title<->meta
#let body-indent = 1 * u // list/code-line horizontal indent

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

#let mark-gutter = 9mm
