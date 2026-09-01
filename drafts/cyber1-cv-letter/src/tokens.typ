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

// ---- Spacing scale (design-cyber §4.4) -----------------------------------
//
// Convention for every block-level spacing call site (markup.typ, resume.typ,
// letter.typ): declare a gap as `below:` on the element that owns it, and
// leave `above: 0pt`, so the rendered gap has one source of truth. `above:`
// is set to a nonzero token only where a show rule genuinely cannot know
// what preceded it — Typst show rules have no sibling lookahead (see the
// comment atop markup.typ), so e.g. the tech-line rule can't tell whether a
// bullet list, a paragraph, or a bare entry header came before it. In those
// cases `above:` is a deliberate floor: Typst collapses adjacent block
// spacing to `max(prev.below, next.above)`, so the nonzero `above` guarantees
// a minimum gap regardless of which element actually precedes it. Never use
// a bare `v()` to bridge two blocks — unlike block `above`/`below`, `v()` is
// an additive spacer that does not participate in that collapse, which is
// exactly the kind of same-looking-but-different-behaviour seam that's hard
// to reason about (see resume.typ's header-block for the pattern to follow
// instead).
//
// Single base unit `u`. Every gap below is a literal `N * u`, absolute
// (`pt`), not `em` — `em` resolves against whichever text context happens
// to be ambient at the call site (design-cyber gives the same reason for
// keeping the type scale in `pt` rather than `em`). Two call sites in
// particular (`body-indent` in resume.typ's list and markup.typ's tech-line
// pad) must resolve to the *identical* physical length to stay visually
// aligned; `em` only guaranteed that by coincidence of both currently
// sitting under the same 10.5pt ambient context, not by construction.
//
// `u` itself is the one tunable knob if the rendered rhythm ever needs
// retuning — retune this single value, never the individual multiples
// (that's what produced the previous, incoherent per-token drift; see git
// history). Determined empirically, not from the spec's literal 4pt: tried
// 4pt and 5pt first, and at both `space-bullet` (1u) rendered smaller than
// the fixed 0.65em wrapped-line leading inside a bullet, so two bullets sat
// closer together than two wrapped lines of the *same* bullet — a real
// cramped signal, not a tuning preference. 6.4pt is the smallest value
// where `space-bullet` clears that leading again, and it also happens to
// match this document's previously-approved density.
#let u = 6.4pt

// design-cyber §4.4 names these as 0.5u/2u/3u/1.5u/4u at the spec's own
// literal 4pt `u` — but that ratio table was never actually the basis for
// this document's previously-approved density (see git history: every
// value below except space-entry was tuned independently, ignoring the
// ratio table it claimed to follow). Re-deriving the *exact* spec ratios
// at this rescaled `u` regresses the rendered CV from 2 pages to 1 —
// verified by rendering — because `space-paragraph` in particular is the
// most-repeated call site and the spec's 0.5u undershoots this document's
// previously-tuned bullet spacing by more than half. The multipliers below
// are instead chosen by rendering and comparing against the previously
// committed PDFs until the page count and rhythm matched again — `u`
// itself came out the same (space-entry was already exactly 2u at 6.4pt;
// see below), but the *other* multipliers had to move off the spec's own
// ratios to land back on the density this document was actually tuned to.
// Shared value for two relationships: the ambient bare-paragraph default
// (resume.typ's `set par(spacing:)`, e.g. SUMMARY's intro paragraph or an
// entry's intro paragraph → its first bullet — this is also what sets the
// gap *around* a whole bullet list, above its first item and below its
// last, since Typst's `list` has no separate above/below of its own and
// falls back to ambient `par.spacing`), and an entry's meta-block → its
// content, paragraph or bullets (markup.typ's render-entry `below:` and
// tech-line-rule's `above:`/`below:`) — reusing one token rather than
// adding a second, separately-tuned constant for what is visually the same
// "ordinary paragraph gap" relationship.
#let space-paragraph = 1.25 * u
// Spacing *between* bullets within one list (resume.typ's `set
// list(spacing:)`) — deliberately its own token, not space-paragraph, so the
// list's own item-to-item rhythm can be tuned independently of the
// surrounding-paragraph gap that wraps the whole list (verified via
// Typst's actual behaviour: `list.spacing` and ambient `par.spacing` are
// already two independent knobs; this just stops them being pinned to the
// same value by accident). Floor is 1u, not lower: same "must clear the
// wrapped-line leading" rule that originally set `u` itself (see above) —
// two bullets sitting closer together than two wrapped lines of the *same*
// bullet is a cramped signal, not a tuning preference. At the current
// leading (resume.typ, 0.6em × 10.5pt body = 6.3pt), 1u (6.4pt) is the
// smallest grid value that still clears it; 0.75u (4.8pt) does not.
#let space-bullet = 1 * u
#let space-entry = 2 * u
// Gap between the content preceding a rule (section-heading text,
// header-block's line stack) and the rule itself (markup.typ's
// section-heading-rule, resume.typ's header-block) — not the gap after the
// rule, which is space-entry / space-header-to-section depending on side.
#let space-section-to-rule = 1.25 * u
// Gap between a section-heading rule and whatever follows it (SUMMARY's
// paragraph, EXPERIENCE's first entry, SKILLS's first row) — the
// section-rule analogue of space-entry/space-paragraph for entry-internal
// gaps. Set as the rule's own `below:`, with the following element's
// `above:` pinned to 0pt so this is the gap's only source (see the
// block-spacing-collapse note atop this file).
#let space-rule-to-content = 0.625 * u
// Space above any section header (design-cyber §4.4) — used uniformly by
// every section heading, including the first: header-block's own `below`
// on the identity block resolves to this same token, so "gap above a
// section header" is one relationship regardless of position, not two that
// happen to collapse to the same value only for the first section.
#let space-header-to-section = 3 * u
// "Header block internal lines" (design-cyber §4.4) — entry title↔org/location
// stack gap (markup.typ's header-stack), and also every adjacent line pair
// in the identity block (resume.typ's header-block) — the same relationship
// one level up, reusing this token rather than a second, separately-tuned
// constant that has to be kept in sync with it by hand.
#let space-header-line = 1 * u
// Not in design-cyber §4.4's table (letter-only). Matches the reference
// HTML's own between-paragraph gap (2.5u) rather than an unrelated constant.
#let space-letter-paragraph = 2.5 * u
// List/tech-line horizontal indent (design-cyber §4.4 doesn't name this one
// either) — snapped onto the same `u` grid for the same reason as the
// vertical tokens above, and to the same 1u multiplier as the other
// previously-"0.65em" group above (see the note by space-bullet).
#let body-indent = 1 * u

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
  tagline: (weight: "regular", size: 10.5pt),
  contact: (weight: "regular", size: 9pt),
  section-header: (weight: "bold", size: 14pt),
  job-title: (weight: "semibold", size: 12pt),
  org-location: (weight: "regular", size: 10.5pt),
  dates: (weight: "regular", size: 9pt),
  body: (weight: "regular", size: 10.5pt),
  tech-line: (weight: "regular", size: 9pt),
  skills-label: (weight: "medium", size: 9pt),
  footer: (weight: "regular", size: 8pt),
)
