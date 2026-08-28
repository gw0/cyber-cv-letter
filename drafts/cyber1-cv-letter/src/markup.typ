// The entry-rendering mechanism — spec/20260828-mvp.md §4, §11.
//
// Show rules keyed on Typst's native elements (heading, list.item, raw,
// terms.item) are the entire rendering mechanism for both the direct-Typst
// and Markdown+Pandoc workflows (§11.1) — Pandoc's Typst writer emits the
// same native elements a direct-Typst author types by hand, so one set of
// rules here serves both.

#import "tokens.typ": *
#import "marks.typ"

// ---------------------------------------------------------------------
// Content-tree helpers
//
// Typst's raw (pre-layout) content sequence has no `list` or `par` wrapper
// node — consecutive list items and paragraph runs are only assembled at
// layout/realization time. That means ordinary show rules (which match a
// single element in isolation, with no sibling awareness) cannot tell "the
// italic meta-line paragraph immediately after an entry heading" apart from
// an unrelated later paragraph — there is no per-element predicate for
// "comes right after X". `render-body` below walks the raw child array once
// to find and pair that one relationship; everything else that doesn't need
// lookahead (section headings, bullets, the tech line, skills) is handled
// by ordinary show rules applied around the walk's output.
// ---------------------------------------------------------------------

// Flattens a content tree to a plain string. Only text and simple
// containers are expected here (the ATS lane is plain text by design,
// design-cyber §2.2), so this does not attempt to handle arbitrary markup.
#let content-to-string(node) = {
  if node.func() == text {
    node.at("text")
  } else if node.has("children") {
    node.children.map(content-to-string).sum(default: "")
  } else if node.has("text") {
    node.at("text")
  } else if node.has("body") {
    content-to-string(node.at("body"))
  } else {
    " "
  }
}

// Recursively finds the first `image` anywhere inside `node`, returning it
// separately from everything else (`rest`, as an array of leaf content).
// Pure-functional (no captured-variable mutation) because Typst closures
// cannot write to variables from an enclosing scope.
#let extract-logo(node) = {
  if node.func() == image {
    (logo: node, rest: ())
  } else if node.has("children") {
    let logo = none
    let rest = ()
    for child in node.children {
      let r = extract-logo(child)
      if logo == none { logo = r.logo }
      rest += r.rest
    }
    (logo: logo, rest: rest)
  } else if node.has("body") {
    extract-logo(node.at("body"))
  } else {
    (logo: none, rest: (node,))
  }
}

// Splits on the *last* `|` (§4: "a title containing `|` is theoretically
// possible"). Returns (left, none) if there is no `|` at all.
#let split-last-pipe(s) = {
  if "|" in s {
    let parts = s.split("|")
    (parts.slice(0, -1).join("|").trim(), parts.last().trim())
  } else {
    (s.trim(), none)
  }
}

// The `*[![](logos/x.png)] Org | Location*` source syntax wraps the image
// in literal `[` `]` characters. In direct Typst those brackets are just
// content-grouping syntax and vanish; from Markdown, Pandoc's Typst writer
// escapes them into real, visible `\[`/`\]` text to preserve them as
// characters — which would otherwise leak stray bracket glyphs into the
// extracted Org/Location text. Strip lone-bracket fragments defensively so
// both workflows converge on identical output.
#let strip-bracket-artifacts(s) = {
  if s.trim() in ("[", "]") { "" } else { s }
}

// ---------------------------------------------------------------------
// Closed section-name vocabulary (design-cyber §7.2, MVP §4/§8)
// ---------------------------------------------------------------------

#let section-vocabulary = (
  "SUMMARY", "PROFESSIONAL SUMMARY",
  "EXPERIENCE", "WORK EXPERIENCE", "PROFESSIONAL EXPERIENCE",
  "PROJECTS", "PERSONAL PROJECTS", "OPEN SOURCE PROJECTS",
  "SKILLS", "TECHNICAL SKILLS",
  "EDUCATION",
  "CERTIFICATIONS",
  "PUBLICATIONS",
  "LANGUAGES",
)

#let section-accent-counter = counter("cv-section-accent")

// Resolves a (possibly out-of-range or negative, e.g. before the first
// section heading) accent-rotation index to a colour, wrapping the same
// way section-heading-rule's own lookup does — the single lookup shared by
// every accent-colour consumer keyed on section position (skills-row-rule,
// logo-cell's placeholder).
#let section-color-at(idx, accent-list) = accent-list.at(calc.rem(calc.max(idx, 0), accent-list.len()))

// ---------------------------------------------------------------------
// Entry rendering
// ---------------------------------------------------------------------

// `## Job Title | Date` — title left, date right, `#h(1fr)`-pushed on one
// line so extraction order is preserved (design-cyber §6.5). Returns bare
// content (no block wrapper) so render-entry can lay it out either as its
// own block or stacked next to a logo cell.
#let entry-title-line(title-node, font, header-font) = {
  let (title, date) = split-last-pipe(content-to-string(title-node.at("body")))
  let tf = resolve-font(font, weight: type-scale.job-title.weight)
  text(font: tf.family, weight: tf.weight, size: type-scale.job-title.size, fill: fg, {
    if date == none {
      title
    } else {
      let df = resolve-font(header-font, weight: type-scale.dates.weight)
      title
      h(1fr)
      text(font: df.family, weight: df.weight, size: type-scale.dates.size, fill: muted)[#date]
    }
  })
}

// The italic meta-line paragraph immediately after an entry heading: an
// optional logo, then `Org | Location` — org left, location right-aligned
// on the same row (mirroring how the title line right-aligns the date
// against the job title). Returns (line: content, logo: image-or-none,
// org: string) — bare content plus the extracted logo, so render-entry can
// place the logo beside the title+meta pair rather than beside meta alone.
#let entry-meta-parts(meta-node, font) = {
  let extracted = extract-logo(meta-node.at("body"))
  let rest-text = extracted.rest
    .map(content-to-string)
    .map(strip-bracket-artifacts)
    .sum(default: "")
  let (org, location) = split-last-pipe(rest-text)
  let bf = resolve-font(font, weight: type-scale.org-location.weight)
  let line = text(font: bf.family, weight: bf.weight, size: type-scale.org-location.size, fill: fg, {
    if location == none {
      org
    } else {
      org
      h(1fr)
      location
    }
  })
  (line: line, logo: extracted.logo, org: org)
}

// `show-logos: true` reserves a logo cell on *every* entry — filled with
// the image if present, a generic placeholder mark otherwise (§5) — sized
// to sit beside the combined title+meta block rather than the meta line
// alone, like a company logo does on a typical resume. The placeholder's
// colour tracks the entry's current section accent (§6) — resolved in
// `context` since it depends on `section-accent-counter`'s value at this
// point in the document.
#let logo-cell(logo, org, accent-list) = if logo != none {
  box(width: logo-width, height: logo-height, clip: true,
    image(logo.at("source"), width: 100%, height: 100%, fit: "contain", alt: org))
} else {
  context {
    let idx = section-accent-counter.get().at(0) - 1
    marks.placeholder-logo(section-color-at(idx, accent-list), logo-width, logo-height)
  }
}

// Renders one entry: the title line, and — if a meta-line paragraph
// followed it — the org/location line below. With `show-logos: true` and a
// meta-line present, both lines are stacked in a column next to one shared,
// vertically-centred logo cell instead of the meta line getting its own.
#let render-entry(title-node, meta-node, font, header-font, show-logos, accent-list) = {
  let title-line = entry-title-line(title-node, font, header-font)

  if meta-node == none {
    block(above: space-entry, below: 0pt, title-line)
  } else {
    let meta = entry-meta-parts(meta-node, font)
    if show-logos {
      block(above: space-entry, below: space-meta,
        grid(columns: (logo-width, 1fr), column-gutter: 4mm, align: (horizon + center, top),
          logo-cell(meta.logo, meta.org, accent-list),
          stack(dir: ttb, spacing: 0pt, title-line, v(space-bullet * 0.5), meta.line),
        )
      )
    } else {
      block(above: space-entry, below: 0pt, title-line)
      block(above: space-meta, below: space-meta, meta.line)
    }
  }
}

// Walks the body's raw child sequence once, pairing each level-2 heading
// with the meta-line paragraph immediately following it (§11.2 — the one
// mechanism prototyped and verified before the rest of this file was
// written). Everything else passes through untouched for the show rules
// below to style.
#let render-body(body, font: "IBM Plex Sans", header-font: "IBM Plex Mono", show-logos: false, accent-list: (fg,)) = {
  let kids = body.children
  let n = kids.len()
  let i = 0
  while i < n {
    let k = kids.at(i)
    if k.func() == heading and k.at("depth") == 2 {
      let title-node = k
      i += 1
      while i < n and kids.at(i).func() not in (emph, heading) {
        i += 1
      }
      let meta-node = if i < n and kids.at(i).func() == emph { kids.at(i) } else { none }
      if meta-node != none { i += 1 }
      render-entry(title-node, meta-node, font, header-font, show-logos, accent-list)
    } else {
      k
      i += 1
    }
  }
}

// ---------------------------------------------------------------------
// Standalone-element show rules (no lookahead needed) — applied by
// resume.typ / letter.typ around a `render-body` call.
// ---------------------------------------------------------------------

// `# Heading` — section header: drawn chevron, vocabulary check (fails the
// build outside §7.2's closed list), full-width rule, accent colour
// (single preset, or friggeri-style rotation indexed by document order and
// wrapping — design-cyber §4.6).
#let section-heading-rule(accent-list, accent-scope, header-font, draw-marks: true) = {
  (it => {
    let raw-text = content-to-string(it.body).trim()
    assert(
      upper(raw-text) in section-vocabulary,
      message: "section heading \"" + raw-text + "\" is outside the closed vocabulary (design-cyber §7.2) — rename it or extend section-vocabulary deliberately",
    )
    section-accent-counter.step()
    context {
      let idx = section-accent-counter.get().at(0) - 1
      let color = section-color-at(idx, accent-list)
      let hf = resolve-font(header-font, weight: type-scale.section-header.weight)
      let display = upper(raw-text)
      let heading-text = if accent-scope == "first3" and display.len() > 3 {
        text(fill: color)[#display.slice(0, 3)] + text(fill: fg)[#display.slice(3)]
      } else {
        text(fill: color)[#display]
      }
      block(above: space-section, below: space-rule-to-entry, breakable: false,
        stack(dir: ttb, spacing: space-rule-to-entry / 2,
          {
            if draw-marks {
              place(dx: -mark-gutter, marks.chevron(color, header-font, type-scale.section-header.size))
            }
            text(font: hf.family, weight: hf.weight, size: type-scale.section-header.size, tracking: 0.08em)[#heading-text]
          },
          marks.rule(color),
        )
      )
    }
  })
}

// Trailing inline-code-only paragraph — the per-role tech line (design-cyber
// §6.5/§9.2). Inline code is not used anywhere else in the ATS lane, so a
// blanket rule on `raw` is safe without needing lookahead.
//
// The list's body text starts at `indent + marker-width + body-indent`
// (resume.typ sets `indent: 0pt`, `body-indent: body-indent`), not at
// `body-indent` alone — the bullet glyph's own rendered width sits in
// between. Measuring it here (rather than hardcoding an offset) keeps the
// tech line aligned with bullet text regardless of font/marker choice.
#let tech-line-rule(header-font, font) = {
  (it => context {
    let hf = resolve-font(header-font, weight: type-scale.tech-line.weight)
    let bf = resolve-font(font, weight: type-scale.body.weight)
    let marker-width = measure(
      text(font: bf.family, weight: bf.weight, size: type-scale.body.size)[•]
    ).width
    block(above: space-bullet, below: space-entry, pad(left: body-indent + marker-width,
      text(font: hf.family, weight: hf.weight, size: type-scale.tech-line.size, fill: muted)[#it.text]
    ))
  })
}

// Skills row: `Category: values` as one inline line via a fixed-width
// label box — never a table()/grid() (design-cyber §6.6). Overrides
// Pandoc's default `#terms` two-line rendering.
// Pandoc wraps a definition list's description in a block-level #block[..],
// which would force the values onto their own line after the inline label
// box below (a block always starts a new line). Unwrap it first — direct
// Typst's `/ Term: value` shorthand never produces this wrapper, so this
// is a no-op for that workflow.
#let unwrap-block(node) = {
  if node.func() == block { node.at("body") } else { node }
}

#let skills-row-rule(font, header-font, accent-list) = {
  (it => context {
    let hf = resolve-font(header-font, weight: type-scale.skills-label.weight)
    let bf = resolve-font(font, weight: type-scale.body.weight)
    let idx = section-accent-counter.get().at(0) - 1
    let label-color = section-color-at(idx, accent-list)
    block(above: 0pt, below: space-bullet, {
      box(width: 38mm,
        text(font: hf.family, weight: hf.weight, size: type-scale.skills-label.size, fill: label-color)[#it.term])
      text(font: bf.family, weight: bf.weight, size: type-scale.body.size, fill: fg)[#unwrap-block(it.description)]
    })
  })
}
