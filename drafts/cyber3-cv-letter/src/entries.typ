// The section/entry parsing state machine. One full content-tree walk:
// split the body at H1 boundaries into sections, split entry-shaped
// sections at H2 boundaries into entries, dispatch each section by the
// shape of its children (not by its name) into entries / skills-row /
// freeform rendering. Fresh heading() calls are re-emitted for section and
// entry titles so PDF outline/tagging comes for free, without any active
// show rule to recurse into.

#import "content.typ": flatten-text, split-last, join-content, split-paragraphs, get-children
#import "theme.typ": fg, muted, note-tint, accent-at, resolve-font, space-paragraph, space-bullet, space-entry, space-section-to-rule, space-rule-to-content, space-header-to-section, space-header-line, body-indent, mark-gutter
#import "marks.typ": draw-chevron, draw-rule, draw-placeholder-logo
#import "ats.typ": artifact

// ---- tree-walking primitives ----------------------------------------------

// Pure inter-block whitespace: a parbreak in hand-authored Typst, or the
// "space" runs Pandoc's typst writer emits after a heading's
// auto-generated label instead of a parbreak. Both are safe to skip when
// looking for the next meaningful sibling.
#let is-gap(node) = node.func() == parbreak or repr(node.func()) == "space"

// Splits a flat node list into (heading, children) groups at every heading
// of the given depth. Any content before the first such heading is dropped
// — the markup contract never expects meaningful content there.
#let split-by-heading(kids, depth) = {
  let n = kids.len()
  let i = 0
  while i < n and not (kids.at(i).func() == heading and kids.at(i).at("depth") == depth) {
    i += 1
  }
  let groups = ()
  while i < n {
    let h = kids.at(i)
    i += 1
    let children = ()
    while i < n and not (kids.at(i).func() == heading and kids.at(i).at("depth") == depth) {
      children.push(kids.at(i))
      i += 1
    }
    groups.push((heading: h, children: children))
  }
  groups
}

// Strips a Pandoc definition-list description's #block[...] wrapper so its
// always-wrapped form and direct-Typst's never-wrapped form read the same.
#let unwrap-block(node) = {
  if node.func() == block { node.at("body") } else { node }
}

// ---- section-shape dispatch (shape, not name) -----------------------------

#let is-entry-shaped(children) = children.any(k => k.func() == heading and k.at("depth") == 2)

#let is-skills-shaped(children) = {
  let meaningful = children.filter(k => not is-gap(k))
  meaningful.len() > 0 and meaningful.all(k => k.func() == terms.item)
}

// ---- meta-line / logo extraction ------------------------------------------

// Detects a box-wrapped image node inside the meta paragraph for the entry
// logo (rather than requiring literal bracket characters as a strip-later
// signal), else falls back to split-last on "|" for org/location.
#let extract-meta(emph-node) = {
  let kids = get-children(emph-node.at("body"))
  let logo = none
  let text-nodes = ()
  for k in kids {
    if logo == none and k.func() == box and k.at("body").func() == image {
      // Keep the already-parsed image node itself (not just its path
      // string) — Typst resolves a relative image path against the file
      // that lexically contains the image() call, so reconstructing a
      // fresh image() call here (in this package file) would re-resolve
      // the author's path against the wrong directory.
      logo = k.at("body")
    } else {
      text-nodes.push(k)
    }
  }
  let line = text-nodes.map(flatten-text).join("").trim()
  let (org, location) = split-last(line, "|")
  (logo: logo, org: org, location: location)
}

// ---- bullets / notes / code line -------------------------------------------

// A note line: the muted annotation immediately under a bullet, rendered
// only when show-notes is true.
#let render-note(note-node, font-body) = {
  set text(..resolve-font(font-body, weight: "regular"), size: 9.5pt, fill: note-tint)
  // .trim() matters here specifically: Pandoc's blockquote-in-list-item
  // output carries a leading "space" run before the actual text (the same
  // kind of artifact is-gap filters at the block level), which
  // flatten-text renders literally — visibly shifting this line right of
  // the bullet text it's supposed to align with.
  block(above: space-bullet, below: 0pt, flatten-text(note-node.at("body")).trim())
}

#let render-bullet-item(item, font-body, font-chrome, show-notes) = {
  let kids = get-children(item.at("body"))
  let note = none
  let text-kids = kids
  if kids.len() > 0 and kids.last().func() == quote {
    note = kids.last()
    text-kids = kids.slice(0, -1)
    if text-kids.len() > 0 and is-gap(text-kids.last()) {
      text-kids = text-kids.slice(0, -1)
    }
  }
  let body = join-content(text-kids)
  if show-notes and note != none {
    body += render-note(note, font-body)
  }
  list.item(body)
}

// ---- entry rendering -------------------------------------------------------

#let render-entry-body(children, color, font-body, font-chrome, show-notes) = {
  let n = children.len()
  let i = 0

  let prose-nodes = ()
  while i < n and children.at(i).func() != list.item and children.at(i).func() != raw {
    prose-nodes.push(children.at(i))
    i += 1
  }
  for para in split-paragraphs(prose-nodes) {
    if para.len() == 0 { continue }
    block(above: 0pt, below: space-paragraph, {
      set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: fg)
      set par(spacing: 0pt)
      join-content(para)
    })
  }

  let bullet-items = ()
  while i < n {
    if children.at(i).func() == list.item {
      bullet-items.push(children.at(i))
      i += 1
    } else if is-gap(children.at(i)) and i + 1 < n and children.at(i + 1).func() == list.item {
      i += 1 // a "space"/parbreak sibling between two bullets — not the end of the list
    } else {
      break
    }
  }
  if bullet-items.len() > 0 {
    block(above: 0pt, below: space-paragraph, {
      set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: fg)
      list(
        indent: 0pt,
        body-indent: body-indent,
        spacing: space-bullet,
        marker: [•],
        ..bullet-items.map(item => render-bullet-item(item, font-body, font-chrome, show-notes)),
      )
    })
  }

  while i < n and is-gap(children.at(i)) { i += 1 }
  if i < n and children.at(i).func() == raw {
    let code = children.at(i)
    context {
      set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: fg)
      let marker-width = measure([•]).width
      block(above: 0pt, below: 0pt, inset: (left: body-indent + marker-width), {
        set text(..resolve-font(font-chrome, weight: "regular"), size: 9pt, fill: muted)
        code.at("text")
      })
    }
  }
}

#let render-entries(children, color, font-body, font-chrome, show-logos, show-notes) = {
  for e in split-by-heading(children, 2) {
    let (title, date) = split-last(flatten-text(e.heading.at("body")), "|")
    let i = 0
    let n = e.children.len()
    while i < n and is-gap(e.children.at(i)) { i += 1 }
    let meta = none
    if i < n and e.children.at(i).func() == emph {
      meta = extract-meta(e.children.at(i))
      i += 1
    }
    while i < n and is-gap(e.children.at(i)) { i += 1 }

    let title-date-line = block(above: 0pt, below: 0pt, {
      set text(..resolve-font(font-body, weight: "semibold"), size: 12pt, fill: fg)
      title
      if date != none {
        h(1fr)
        set text(..resolve-font(font-chrome, weight: "regular"), size: 9pt, fill: color)
        date
      }
    })

    let meta-line = if meta != none {
      block(above: 0pt, below: 0pt, {
        set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: muted)
        if meta.org != none { meta.org }
        if meta.location != none { h(1fr); meta.location }
      })
    } else { none }

    let header = if meta-line != none {
      stack(dir: ttb, spacing: space-header-line, title-date-line, meta-line)
    } else {
      title-date-line
    }

    let head = if show-logos and meta != none {
      // Purely decorative — the org name right next to it already carries
      // the same information — so it's a PDF artifact, exempt from PDF/UA-1
      // alt-text requirements. This also sidesteps a real Pandoc writer
      // limitation: alt text on an inline (non-block) markdown image is
      // silently dropped by Pandoc's typst writer, so relying on authored
      // alt text here wouldn't work uniformly across both workflows anyway.
      // A logo-less entry still reserves the column (a placeholder mark in
      // the entry's accent color) so sibling entries within a section stay
      // aligned regardless of which ones have a real logo.
      let logo-content = if meta.logo != none {
        artifact(box(width: 3em, height: 2em, clip: true, align(center + horizon, meta.logo)), kind: "other")
      } else {
        draw-placeholder-logo(color)
      }
      grid(
        columns: (3em, 1fr), column-gutter: 4mm, align: (horizon + center, top),
        logo-content, header,
      )
    } else {
      header
    }

    block(above: 0pt, below: space-entry, breakable: false, {
      heading(level: 2, head)
      render-entry-body(e.children.slice(i), color, font-body, font-chrome, show-notes)
    })
  }
}

// ---- skills row -------------------------------------------------------------

// One line of real text per row: a monospace (font-chrome) label padded
// with literal space characters, not a box/table gutter — several PDF text
// extractors (pymupdf's default plain-text mode included) insert a
// spurious line break when a box's reserved width leaves a large
// glyph-free gap on the line, even at the same baseline.
#let render-skills-section(children, color, font-chrome, font-body) = {
  let items = children.filter(k => k.func() == terms.item)
  let label-chars = items.map(item => flatten-text(item.at("term")).trim().len()).fold(0, calc.max) + 2
  for item in items {
    let label = flatten-text(item.at("term")).trim()
    let desc = flatten-text(unwrap-block(item.at("description"))).trim()
    block(above: 0pt, below: space-bullet, {
      text(..resolve-font(font-chrome, weight: "medium"), size: 9pt, fill: color, label + " " * (label-chars - label.len()))
      text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: fg, desc)
    })
  }
}

// ---- freeform prose ----------------------------------------------------------

#let render-freeform-section(children, font-body) = {
  for para in split-paragraphs(children) {
    if para.len() == 0 { continue }
    block(above: 0pt, below: space-paragraph, {
      set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: fg)
      set par(spacing: 0pt)
      join-content(para)
    })
  }
}

// ---- section header + dispatch ------------------------------------------------

#let render-section-header(name, color, font-chrome, accent-scope) = block(
  above: space-header-to-section, below: 0pt, breakable: false,
  {
    // dy re-measured empirically (pixel-scanned ink bounding boxes via
    // pymupdf) against the heading text's actual vertical center at 14pt
    // bold — not derived from arithmetic, since the ambient em here is the
    // 10.5pt body size in scope at this call site, not the heading's own.
    place(dx: -mark-gutter, dy: -0.175pt, draw-chevron(color))
    block(above: 0pt, below: space-section-to-rule, heading(level: 1, {
      set text(..resolve-font(font-chrome, weight: "bold"), size: 14pt)
      if accent-scope == "first3" and name.len() > 3 {
        text(fill: color, name.slice(0, 3)) + text(fill: fg, name.slice(3))
      } else {
        text(fill: color, name)
      }
    }))
    draw-rule(color)
  },
)

#let render-section(name, color, children, font-body, font-chrome, show-logos, show-notes, accent-scope) = {
  render-section-header(name, color, font-chrome, accent-scope)
  block(above: space-rule-to-content, below: 0pt, {
    if is-entry-shaped(children) {
      render-entries(children, color, font-body, font-chrome, show-logos, show-notes)
    } else if is-skills-shaped(children) {
      render-skills-section(children, color, font-chrome, font-body)
    } else {
      render-freeform-section(children, font-body)
    }
  })
}

// ---- top-level entrypoint --------------------------------------------------

#let render-cv-body(body, accent-list, accent-scope, font-body, font-chrome, show-logos, show-notes) = {
  let kids = get-children(body)
  let sections = split-by-heading(kids, 1)
  for (index, sec) in sections.enumerate() {
    let name = upper(flatten-text(sec.heading.at("body")))
    let color = accent-at(accent-list, index)
    render-section(name, color, sec.children, font-body, font-chrome, show-logos, show-notes, accent-scope)
  }
}
