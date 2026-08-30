// Design tokens: palette, accent presets, spacing scale, type scale, page geometry.
// Binding source: specs/20260821-design-cyber.md §4, folded through
// specs/20260828-mvp.md §4.

// ---- Palette (design-cyber.md §4.1) ----
#let bg = rgb("#ffffff")
#let fg = rgb("#3c3836")
#let muted = rgb("#7c6f64")
#let secondary = rgb("#076678")
#let surface = rgb("#fbf1c7") // web-only, unused in PDF output

// Master-CV comment tint: several steps lighter than `muted`, print-legible
// annotation-only color (mvp spec §10). Not AA-contrast-checked on purpose:
// this text never ships to an employer.
#let comment-tint = rgb("#b8b2a8")

// ---- Accent presets (design-cyber.md §4.2, §4.6) ----
#let accent-green = rgb("#157d00")
#let accent-red = rgb("#af3a03")
#let accent-friggeri = (
  rgb("#008194"),
  rgb("#eb0054"),
  rgb("#ad6000"),
  rgb("#628000"),
  rgb("#a638ff"),
)

// Resolve the `accent` config parameter (mvp spec §7) into either a single
// color or an array of colors (friggeri rotation). Accepts "green" | "red" |
// "friggeri" | a hex string | an array of hex strings.
#let resolve-accent(value) = {
  if type(value) == str {
    if value == "green" { accent-green }
    else if value == "red" { accent-red }
    else if value == "friggeri" { accent-friggeri }
    else { rgb(value) }
  } else if type(value) == array {
    value.map(v => if type(v) == str { rgb(v) } else { v })
  } else {
    value
  }
}

// Pick the accent color for the `index`-th section header (0-based),
// wrapping around when `accent` is a list (design-cyber.md §4.6).
#let accent-for(accent, index) = {
  if type(accent) == array {
    accent.at(calc.rem(index, accent.len()))
  } else {
    accent
  }
}

// `plain` build variant (design-cyber.md §9.3): motifs and accent
// stripped, black text, plain rules, identical structure and content. A
// genuine one-flag build — selected via `--input variant=plain` (Typst
// `sys.inputs`), never by editing content.
#let is-plain-variant() = sys.inputs.at("variant", default: "themed") == "plain"

// Resolve the effective accent, collapsing to `fg` under the plain variant.
#let effective-accent(accent-value) = {
  if is-plain-variant() { fg } else { accent-value }
}

// ---- Spacing scale (design-cyber.md §4.4) ----
// Em units, resolved against the ambient body text size at each call site
// (the global `set text(size: size-body, ...)` in cv()/cover-letter() —
// every spacing call below sits in that context, not inside a nested
// `set text` for a differently-sized run). Starting values adapted from
// specs/20260821-rev-modern-cv.md §2.2 (`resume-entry` 1em/0.65em,
// `resume-item` 0.5em, `justified-header` 0.7em, skill-item 0.65em), then
// visually tuned to fix the fused title/meta/tagline/first-bullet read
// and the section rule's cramped hand-tuned offset. `title-to-meta` and
// `skills-row-to-row` were later folded onto the same tight-tier value as
// `header-internal`/`bullet-to-bullet` (0.4em) — same visual role (lines
// within one grouped unit); they'd drifted to their own one-off values
// (0.35em, 0.2em — the latter read as rows nearly touching) for no reason
// tied to the content they space. Raising `skills-row-to-row` the full
// distance needed page 1 to gain back a few points of room, so
// `rule-to-content` (below) also dropped 0.7em -> 0.6em: it fires once per
// section (5x on the example CV), so a small uniform trim there funds the
// fix without being individually noticeable anywhere it's used.
#let spacing-header-to-rule = 0.6em
#let spacing-section-header-to-rule = 0.4em
#let spacing-rule-to-content = 0.6em
#let spacing-title-to-meta = 0.4em
#let spacing-meta-to-tagline = 0.65em
#let spacing-tagline-to-bullets = 0.75em
#let spacing-bullet-to-bullet = 0.4em
#let spacing-bullet-to-comment = 0.3em
#let spacing-to-tech-line = 0.7em
#let spacing-entry-to-entry = 1.1em
#let spacing-section-to-section = 1.6em
#let spacing-letter-paragraph = 1.4em
// Formalizes gaps that were implicit magic numbers before design-cyber.md
// §4.4's revision: 3 hardcoded values inside the header block collapse to
// one named gap, and skills rows get their own gap distinct from bullets.
#let spacing-header-internal = 0.4em
#let spacing-skills-row-to-row = 0.4em

// ---- Type scale (mvp spec §4.2) ----
// Sizes/weights are read directly at each call site in layout.typ; recorded
// here as named constants so the numbers live in one place.
#let size-name = 20pt
#let size-tagline = 10.5pt
#let size-contact = 9pt
#let size-section-header = 14pt
#let size-entry-title = 12pt
#let size-meta = 10.5pt
#let size-body = 10.5pt
#let size-tech = 9pt
#let size-comment = 9.5pt
#let size-skills-label = 9pt
#let size-footer = 8pt
#let size-entry-date = 9pt

// ---- Entry logo geometry (mvp spec §4.4/§13.3 reserved logo column) ----
#let width-entry-logo-box = 14pt
#let width-entry-logo-gutter = 18pt // box + gap reserved before entry text
#let height-entry-logo-box = 11pt

// Tech line indent (design-cyber.md §6.5), so its left edge lines up with
// bullet text rather than the bullet marker. §6.5 documents this as 11pt,
// matching modern-cv's CSS `ul.bul` padding-left — but Typst's own default
// list hanging indent (unset here, so `list`'s built-in default) measures
// 9.4pt from the margin in the rendered PDF, not 11pt. Matched to that
// measured value rather than the spec's borrowed CSS figure.
#let inset-tech-line = 9.4pt

// ---- Page geometry (mvp spec §4.4) ----
#let page-geometry = (
  a4: (
    paper: "a4",
    margin: (top: 16mm, bottom: 16mm, left: 24mm, right: 18mm),
    mark-x: 15mm,
  ),
  us-letter: (
    paper: "us-letter",
    margin: (top: 16mm, bottom: 16mm, left: 25mm, right: 19mm),
    mark-x: 16mm,
  ),
)
