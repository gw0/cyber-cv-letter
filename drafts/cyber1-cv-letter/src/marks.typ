// Drawn decoration primitives — design-cyber §4.5, §2.2/§2.3.
// Decoration is drawn, not typed: every mark here is a vector path wrapped
// in pdf.artifact, contributing zero characters to the text stream.
// src/marks.typ owns the two mark primitives; nothing else draws a mark.

#import "tokens.typ": bg

// One monospace grid cell at the given font/size, measured against the
// active header font so marks stay on-grid even if header-font is swapped.
// Must be called from inside a `context` block — it does not open its own,
// since `measure()` only needs *some* enclosing context, not a dedicated one.
#let cell-width(font, size) = measure(text(font: font, size: size)[0]).width

// Prompt chevron (❯), two 0.6pt strokes meeting at a point, one monospace
// cell wide, on the text baseline. Marks the CV's section headers (§6.4)
// and the cover letter's date line (Appendix A).
#let chevron(color, font, size) = pdf.artifact(kind: "other")[#context {
  let w = cell-width(font, size)
  let h = size * 0.72
  box(width: w, height: h, baseline: h * 0.22, {
    place(line(start: (12%, 8%), end: (78%, 50%), stroke: 0.6pt + color))
    place(line(start: (78%, 50%), end: (12%, 92%), stroke: 0.6pt + color))
  })
}]

// Block cursor (▮), filled rect, 0.6em × 0.7em (one cell, roughly
// cap-height). Marks exactly one position per document: after the name in
// the header block, and reused unmodified to terminate the footer prompt.
#let cursor(color, font, size) = pdf.artifact(kind: "other")[#context {
  let w = cell-width(font, size)
  let h = size * 0.7
  box(width: w, height: h, baseline: h * 0.14, rect(width: w, height: h, fill: color, stroke: none))
}]

// Section rule / header-block rule — a plain horizontal stroke, full column
// width. Section rules use the default 0.6pt; the header-block override
// (resume.typ) draws its rule heavier (1.2pt) to visually anchor the name
// block above the lighter section rules that follow it.
//
// A filled block, not `line()`: a horizontal `line()` reports ~zero size to
// its parent's automatic block-height calculation, so content stacked
// after it (via `v()` inside the same block) ends up laid out on top of
// it instead of below. A block with an explicit height doesn't have that
// problem.
#let rule(color, weight: 0.6pt) = pdf.artifact(kind: "layout")[
  #block(width: 100%, height: weight, fill: color, above: 0pt, below: 0pt)
]

// Generic no-logo placeholder: a small filled aperture (two concentric
// circles), inset within the cell rather than edge-to-edge, so it reads as
// an abstract placeholder mark rather than a plain filled/bordered
// rectangle. `height` is always the cell's shorter side by construction
// (logo cells are 3:2 landscape — tokens.typ), so sizing off it alone is
// enough; no need to compare width/height (which would require `context`,
// since `calc.min` can't compare two different relative lengths outside one).
#let placeholder-logo(color, width, height) = pdf.artifact(kind: "other")[
  #box(width: width, height: height, {
    place(center + horizon, circle(radius: height * 0.3, fill: color))
    place(center + horizon, circle(radius: height * 0.12, fill: bg))
  })
]
