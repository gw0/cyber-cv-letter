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
  let line = text(font: bf.family, weight: bf.weight, size: type-scale.org-location.size, fill: fg, style: "italic", {
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
//
// Both the logo and non-logo paths share one `header-stack`/`above:`/
// `below:` treatment so "title↔meta" and "meta→first bullet/paragraph" are
// each a single deterministic value regardless of which path renders them,
// rather than two branches quietly drifting apart (previously: the logo
// path used space-bullet*0.5 for title↔meta while the non-logo path used
// space-meta for the same relationship).
//
// `above` is supplied by the caller (render-body) — 0pt immediately after a
// section rule (so the rule's own `below: space-rule-to-content` is the
// gap's only source), space-entry otherwise. render-body is the only place
// that knows which case applies; this function just takes the value.
//
// `breakable: false` keeps a title from separating from its own meta line
// (or a logo from its text) across a page break, now that output may span
// multiple pages.
#let render-entry(title-node, meta-node, font, header-font, show-logos, accent-list, above) = {
  let title-line = entry-title-line(title-node, font, header-font)

  if meta-node == none {
    block(above: above, below: space-paragraph, breakable: false, title-line)
  } else {
    let meta = entry-meta-parts(meta-node, font)
    let header-stack = stack(dir: ttb, spacing: space-header-line, title-line, meta.line)
    if show-logos {
      block(above: above, below: space-paragraph, breakable: false,
        grid(columns: (logo-width, 1fr), column-gutter: 4mm, align: (horizon + center, top),
          logo-cell(meta.logo, meta.org, accent-list),
          header-stack,
        )
      )
    } else {
      block(above: above, below: space-paragraph, breakable: false, header-stack)
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
  // Set on a depth-1 (section) heading, consumed by whatever is rendered
  // next — that "next thing" sits right after section-heading-rule's own
  // `below: space-rule-to-content`, so it must contribute 0pt above of its
  // own, or the collapse's max() would let its ambient/default above win
  // instead of the rule's below (see tokens.typ's space-rule-to-content).
  let is-first-after-rule = false
  while i < n {
    let k = kids.at(i)
    if k.func() == heading and k.at("depth") == 1 {
      is-first-after-rule = true
      k
      i += 1
    } else if k.func() == parbreak {
      // A source-level blank line between a section heading and whatever
      // follows it (design-cyber's Markdown-shaped authoring convention —
      // every example CV has one) becomes a literal `parbreak` node here,
      // since Typst's raw content sequence carries it as its own element.
      // Left un-skipped, this was landing in the catch-all branch below
      // *first*, consuming `is-first-after-rule` on a zero-content
      // parbreak instead of the real next element — verified via a
      // `k.func()` dump on the actual SUMMARY body that it really is
      // `parbreak`, not `text`, at that position. That let the genuine
      // next element (the SUMMARY paragraph, or the first EXPERIENCE
      // heading) fall through with its own ambient `above` un-zeroed,
      // *adding* to `space-rule-to-content` rather than collapsing with
      // it — the actual source of the "gap didn't shrink" symptom this
      // was diagnosed from, not the `context`-nesting issue this file's
      // other comments describe (a real, separate, smaller effect, but
      // not the dominant one). Dropping the parbreak outright rather than
      // emitting it is safe: the block wrapping below already establishes
      // its own layout boundary, so the parbreak contributes nothing by
      // being emitted.
      i += 1
    } else if repr(k.func()) == "space" and is-first-after-rule {
      // `space`'s element function has no public global binding (unlike
      // text/parbreak/heading/emph above) — comparing via `repr()` against
      // its printed name is the only way to match it from here.
      //
      // Pandoc's Typst writer never emits a blank-line parbreak between a
      // heading and what follows it (verified: `pandoc --to=typst` on
      // "# Heading\n\nParagraph" produces `= Heading\n<heading>\nParagraph`
      // — a label line, not a blank line). Typst's own parser turns each of
      // the two single newlines around that label line (one after the
      // heading, one after the label) into a `space` content node, and the
      // label itself vanishes into them rather than appearing as a node of
      // its own — so a section or entry heading from the Markdown+Pandoc
      // workflow is followed by two `space` siblings, not one `parbreak`,
      // before the real content. Left unhandled, this is the exact same bug
      // as the parbreak case above (verified via the same k.func() dump,
      // run against Pandoc's actual output for this document): the first
      // stray `space` node falls into the catch-all branch below and
      // consumes `is-first-after-rule` on itself instead of on the real
      // paragraph/entry/skills-row that follows.
      //
      // This skip is gated on `is-first-after-rule` (unlike the
      // unconditional parbreak skip) because a bare `space` node is not
      // always decorative — line-wrapped paragraph text from Pandoc is
      // split into alternating `text`/`space` siblings at each wrap point,
      // and those `space` nodes are real inter-word spaces that must render
      // normally once the flag has already been consumed by the paragraph's
      // first `text` sibling.
      i += 1
    } else if k.func() == heading and k.at("depth") == 2 {
      let title-node = k
      i += 1
      while i < n and kids.at(i).func() not in (emph, heading) {
        i += 1
      }
      let meta-node = if i < n and kids.at(i).func() == emph { kids.at(i) } else { none }
      if meta-node != none { i += 1 }
      let above = if is-first-after-rule { 0pt } else { space-entry }
      render-entry(title-node, meta-node, font, header-font, show-logos, accent-list, above)
      is-first-after-rule = false
    } else {
      if is-first-after-rule {
        // `set par(spacing: 0pt)` here is load-bearing, not decorative: a
        // bare paragraph nested in `block(above: 0pt, ...)` still asserts
        // its own ambient `par.spacing` above itself — measured as a
        // second, independent leak source into the gap that `above: 0pt`
        // was supposed to zero out (on top of the parbreak issue above).
        // Scoping the paragraph's own spacing to 0pt here removes it.
        block(above: 0pt, below: space-paragraph, {
          set par(spacing: 0pt)
          k
        })
        is-first-after-rule = false
      } else {
        k
      }
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
    let hf = resolve-font(header-font, weight: type-scale.section-header.weight)
    let display = upper(raw-text)
    // `block(...)` must be the outermost call here, with `context` nested
    // as its sole child — not the reverse (`context { block(...) }`, this
    // function's previous shape). Empirically, a `context`-wrapped block's
    // own `below:` still governs the gap to its *own* following sibling
    // correctly, but a block *returned from inside* a context stops
    // participating in the normal max()-collapse for whatever comes right
    // after it: measured via a minimal reproduction (render-entry's
    // `above: 0pt` after this rule) that the gap grew by a large fraction
    // of the ambient `space-paragraph` value even with `above: 0pt`
    // explicit — a leak that vanished entirely once `block(...)` was moved
    // outside the `context`. Root cause not fully diagnosed beyond that
    // (a Typst layout-vs-context interaction, not this package's spacing
    // model), but the outside-block shape is verified leak-free and
    // produces identical visual output otherwise.
    block(above: space-header-to-section, below: space-rule-to-content, breakable: false,
      context {
        let idx = section-accent-counter.get().at(0) - 1
        let color = section-color-at(idx, accent-list)
        let heading-text = if accent-scope == "first3" and display.len() > 3 {
          text(fill: color)[#display.slice(0, 3)] + text(fill: fg)[#display.slice(3)]
        } else {
          text(fill: color)[#display]
        }
        stack(dir: ttb, spacing: space-section-to-rule / 2,
          {
            if draw-marks {
              place(dx: -mark-gutter, marks.chevron(color, header-font, type-scale.section-header.size))
            }
            text(font: hf.family, weight: hf.weight, size: type-scale.section-header.size, tracking: 0.08em)[#heading-text]
          },
          marks.rule(color),
        )
      }
    )
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
    block(above: space-paragraph, below: space-paragraph, pad(left: body-indent + marker-width,
      text(font: hf.family, weight: hf.weight, size: type-scale.tech-line.size, fill: muted)[#it.text]
    ))
  })
}

// A blockquote immediately after a bullet — an author's expanded-detail
// comment on that bullet (spec's Master CV idea, simplified here: it
// renders unconditionally whenever present, no config flag). `fill: muted`
// and `type-scale.tech-line.size` reuse the tech line's own "secondary
// annotation" styling rather than adding a new token. Structurally mirrors
// tech-line-rule above: same marker-width measurement so the comment's left
// edge lines up with the bullet's own text (not just its marker), and the
// same explicit `space-paragraph` above/below rather than relying on
// block-collapse with the neighbouring list — measured empirically that
// collapse-based spacing here produced an almost-invisible gap (Typst's
// "tight list" behaviour, no blank lines between `-` items in this
// document's source, doesn't hand the list's outer edge the `space-bullet`
// token's literal value the way a naive collapse would suggest).
// No `leading` override here — a wrapped comment's own line-to-line
// spacing uses the same ambient 0.6em set document-wide (resume.typ's
// `set par(..., leading: 0.6em, ...)`), the one leading value this
// document already uses for every other piece of body-ish text, rather
// than a bespoke third value.
#let comment-rule(font) = {
  (it => context {
    let bf = resolve-font(font, weight: type-scale.body.weight)
    let marker-width = measure(
      text(font: bf.family, weight: bf.weight, size: type-scale.body.size)[•]
    ).width
    block(above: space-paragraph, below: space-paragraph, breakable: false,
      pad(left: body-indent + marker-width,
        text(font: bf.family, size: type-scale.tech-line.size, fill: muted)[#it.body]
      )
    )
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

// Recursively collects every `terms.item` node's raw `term` field found
// anywhere inside `node`. Walks the same shape of raw content tree as
// `content-to-string`/`extract-logo` above.
//
// This exists (rather than `query(terms)` from inside the show rule below)
// because `query()` for an element type can't resolve from within the show
// rule that produces that very element's realized children: showing a
// `terms.item` is part of what expanding its parent `terms` element means,
// so a query for `terms` issued mid-expansion has nothing finished to find
// yet and silently returns empty forever (verified — the query-based
// version rendered every label at ~0 width, overlapping the description
// text). Walking the pre-show raw tree sidesteps that: `.term` is static
// source data, available before any show rule runs.
#let collect-skill-labels(node) = {
  if node.func() == terms.item {
    (node.at("term"),)
  } else if node.has("children") {
    node.children.map(collect-skill-labels).flatten()
  } else if node.has("body") {
    collect-skill-labels(node.at("body"))
  } else {
    ()
  }
}

// Measures the widest skills-label term in `body` up front, so the column
// can be sized once, before rendering, rather than per-row (see
// collect-skill-labels for why per-row query() doesn't work). Must be
// called from within an existing `context` (measure() requires one) — the
// call site is resume.typ's cv-resume, alongside the show-rule setup.
//
// The closed section vocabulary only ever produces one skills-style
// (terms) section per CV, so measuring every label document-wide is
// equivalent to measuring per-section in practice.
#let skills-label-width(body, font, header-font) = {
  let hf = resolve-font(header-font, weight: type-scale.skills-label.weight)
  // 4mm gutter matches render-entry's logo-cell column-gutter (line 211) —
  // same "space after a fixed first column" relationship.
  calc.max(0pt, ..collect-skill-labels(body).map(term => measure(
    text(font: hf.family, weight: hf.weight, size: type-scale.skills-label.size)[#term]
  ).width)) + 4mm
}

// `block(...)` is the outermost call, `context` nested as its sole child —
// same leak-avoiding shape as section-heading-rule (see that function's
// comment); a `context { block(...) }` here measurably let this row's
// `above: 0pt` leak against a section-heading-rule's `below:` for the
// first SKILLS row.
#let skills-row-rule(font, header-font, accent-list, label-width) = {
  (it => block(above: 0pt, below: space-paragraph,
    context {
      let hf = resolve-font(header-font, weight: type-scale.skills-label.weight)
      let bf = resolve-font(font, weight: type-scale.body.weight)
      let idx = section-accent-counter.get().at(0) - 1
      let label-color = section-color-at(idx, accent-list)
      box(width: label-width,
        text(font: hf.family, weight: hf.weight, size: type-scale.skills-label.size, fill: label-color)[#it.term])
      text(font: bf.family, weight: bf.weight, size: type-scale.body.size, fill: fg)[#unwrap-block(it.description)]
    }
  ))
}
