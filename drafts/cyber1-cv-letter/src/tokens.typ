// Design tokens — spec/20260828-mvp.md §3, carrying design-cyber §4 verbatim.
// Single source of truth for palette, spacing, type scale, and font-weight resolution.
// Do not hardcode a hex or size anywhere else in the package.

// ---- Palette (design-cyber §4.1) ----------------------------------------

#let bg = rgb("#ffffff")
#let fg = rgb("#3c3836")
#let muted = rgb("#7c6f64")
#let secondary = rgb("#076678")

// ---- Accent presets (design-cyber §4.1, §4.2, §4.6) ---------------------
// Each preset is a *list* of colours so accent-scope's "friggeri" rotation
// and a single-colour preset share one code path (§4.6).

#let accent-presets = (
  red: (rgb("#af3a03"),),
  green: (rgb("#157d00"),),
  friggeri: (
    rgb("#008194"),
    rgb("#eb0054"),
    rgb("#ad6000"),
    rgb("#628000"),
    rgb("#a638ff"),
  ),
)

// Resolves the `accent` parameter (preset name, or a list of colours/hex
// strings for a custom rotation) to a list of colours. Custom lists are the
// implementer's responsibility to verify against the AA floor (§4.2) —
// see scripts/check_contrast.py.
#let resolve-accent(accent) = {
  if type(accent) == str {
    assert(
      accent in accent-presets,
      message: "unknown accent preset: " + accent + " (expected one of " + accent-presets.keys().join(", ") + ", or a custom colour list)",
    )
    accent-presets.at(accent)
  } else if type(accent) == array {
    accent.map(c => if type(c) == str { rgb(c) } else { c })
  } else {
    (accent,)
  }
}

// `accent-scope`: "full" colours the whole heading text; "first3" colours
// only the first 3 letters, rest in `fg` (design-cyber §6.4, §4.6).
#let accent-scope-values = ("full", "first3")

// ---- Spacing scale (design-cyber §4.4, adapted from modern-cv's em-based
// rhythm — spec/20260821-rev-modern-cv.md §2.2, §7.4 R4.1) -----------------
// `em`-relative so spacing scales with local text size, expressed through
// this small set of named, reused tokens rather than per-call-site literals.
//
// modern-cv's own magnitudes (bullet 0.65em, entry 1em, section 1.25em,
// rule-to-entry 0.75em, header-to-section 1.75em) were originally scaled
// down to ~65% to fight an oversized par leading (1.35em) that ate the
// one-page budget. With leading fixed (resume.typ), that budget goes back
// into space-entry/space-section instead — still below modern-cv's own
// magnitudes, keeping the bullet < entry < section < header-to-section
// ordering intact.

#let space-bullet = 0.423em
#let space-meta = 0.6em
#let space-entry = 0.9em
#let space-section = 1.05em
#let space-rule-to-entry = 0.488em
#let space-header-to-section = 1.137em
#let space-letter-paragraph = 1.5em
#let space-header-line = 0.35em
#let body-indent = 0.65em

// Company logo cell (render-entry, markup.typ): landscape, matching a
// typical wordmark's aspect ratio rather than a portrait headshot's — sized
// to sit comfortably beside the combined job-title + org/location height.
// em-relative like the rest of this scale, so the cell scales with the
// local text size it sits beside rather than staying a fixed physical size.
#let logo-width = 3em
#let logo-height = 2em

// The mark position sits 9mm left of the text column on both paper sizes
// (design-cyber §6.1: 15mm/24mm on A4, 16mm/25mm on US Letter — both a
// 9mm gutter). Page margins are set to the text-column edge; the chevron
// is `place()`d at `-mark-gutter` to hang in that reserved margin space
// without disturbing the text flow it sits beside (§2.3).
#let mark-gutter = 9mm

// Page geometry (design-cyber §6.1).
#let page-geometry = (
  a4: (paper: "a4", top: 16mm, bottom: 16mm, left: 24mm, right: 18mm),
  us-letter: (paper: "us-letter", top: 16mm, bottom: 16mm, left: 25mm, right: 19mm),
)

// ---- Font-weight resolution -----------------------------------------------
//
// IBM Plex ships Medium (500) and SemiBold (600) as separate Typst font
// *families* ("IBM Plex Mono Medm" / "IBM Plex Mono SmBld"), not as weight
// variants of the base family — the base family only spans
// Thin/ExtraLight/Light/Regular/Bold plus their italics. Requesting
// weight:"medium" on the base family would silently fall back to the
// nearest weight Typst can find, not the real Medium glyphs. This table is
// how known font families expose their extra weights; families not listed
// here are assumed to carry every weight under one family name (true for
// Roboto and Source Sans Pro, the alternate families this package ships).
#let font-weight-families = (
  "IBM Plex Mono": (medium: "IBM Plex Mono Medm", semibold: "IBM Plex Mono SmBld"),
  "IBM Plex Sans": (medium: "IBM Plex Sans Medm", semibold: "IBM Plex Sans SmBld"),
)

// Returns a (family:, weight:) pair suitable for `text(..)`'s named args.
#let resolve-font(base-family, weight: "regular") = {
  let special = font-weight-families.at(base-family, default: (:))
  if weight in special {
    (family: special.at(weight), weight: "regular")
  } else {
    (family: base-family, weight: weight)
  }
}

// Pandoc's template-variable substitution runs plain YAML metadata strings
// (author.email, links, ...) through its Typst writer's markup-escaping —
// correct when a variable lands in markup, but this package's pandoc
// templates interpolate them inside quoted Typst string literals instead,
// where e.g. "\@" isn't a recognised escape and survives as a literal
// backslash. Strip that class of artifact; direct-Typst-authored strings
// never contain it, so this is a no-op for that workflow.
#let unescape-metadata(s) = {
  for ch in ("@", "#", "$", "_", "*", "~", "%", "&", "\"") {
    s = s.replace("\\" + ch, ch)
  }
  s
}

#let sanitize-author(author) = {
  let out = (:)
  for (key, value) in author {
    out.insert(key, if type(value) == str {
      unescape-metadata(value)
    } else if type(value) == array {
      value.map(v => if type(v) == str { unescape-metadata(v) } else { v })
    } else {
      value
    })
  }
  out
}

// ---- Type scale (design-cyber §5.3) --------------------------------------
// Each entry is resolved against the active `font`/`header-font` at call
// time (see markup.typ / resume.typ), since family names are configurable.

#let type-scale = (
  name: (weight: "bold", size: 20pt),
  tagline: (weight: "regular", size: 11pt),
  contact: (weight: "regular", size: 9pt),
  section-header: (weight: "bold", size: 11pt),
  job-title: (weight: "semibold", size: 12pt),
  org-location: (weight: "regular", size: 10.5pt),
  dates: (weight: "regular", size: 9.5pt),
  body: (weight: "regular", size: 10.5pt),
  tech-line: (weight: "regular", size: 9pt),
  skills-label: (weight: "medium", size: 9.5pt),
  footer: (weight: "regular", size: 8pt),
)
