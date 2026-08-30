// Page setup, header block, section rule + chevron drawing, and the
// entry-grouping engine (mvp spec §6). Implemented as full content-tree
// introspection (mvp spec §6, option (a)): the whole document body is
// walked once, split into sections at H1 boundaries and entries at H2
// boundaries, and re-emitted as freshly-constructed content. Because the
// replacement content is built directly in script (not via a `show
// heading: ...` interception), fresh `heading()` calls here are not
// re-matched by any active show rule, so no recursion guard is needed and
// PDF/UA-1 heading semantics (tagging, outline) come for free.

#import "theme.typ": *
#import "ats.typ": artifact, set-metadata
#import "icons.typ": icon

// ---------------------------------------------------------------------
// Plain-text extraction and string helpers
// ---------------------------------------------------------------------

#let is-space-func(f) = repr(f) == "space"

#let flatten-text(c) = {
  if type(c) == str {
    c
  } else if type(c) == content {
    let f = c.func()
    if is-space-func(f) {
      " "
    } else if f == linebreak or f == parbreak {
      " "
    } else if c.has("text") {
      c.text
    } else if c.has("children") {
      c.children.map(flatten-text).join("")
    } else if c.has("body") {
      flatten-text(c.body)
    } else {
      ""
    }
  } else {
    ""
  }
}

// Split on the *last* occurrence of `sep`. Returns (left, right), both
// trimmed. If `sep` doesn't occur, `right` is none.
#let split-last(s, sep) = {
  if s.contains(sep) {
    let parts = s.split(sep)
    let right = parts.last()
    let left = parts.slice(0, parts.len() - 1).join(sep)
    (left.trim(), right.trim())
  } else {
    (s.trim(), none)
  }
}

// Join an array of content nodes into a single content value.
#let join-content(nodes) = nodes.fold([], (acc, x) => acc + x)

#let is-sep-func(f) = is-space-func(f) or f == parbreak or f == linebreak

// Drop trailing separator nodes from a node list (mirrors the leading-node
// drop already done while accumulating).
#let trim-trailing-seps(nodes) = {
  let end = nodes.len()
  while end > 0 and is-sep-func(nodes.at(end - 1).func()) {
    end -= 1
  }
  nodes.slice(0, end)
}

// Split a flat list of inline content nodes into paragraphs on `parbreak`
// boundaries, dropping leading and trailing separator nodes within each
// paragraph. Trailing separators matter at document/section end: with no
// following `parbreak` to close the paragraph, a stray trailing space node
// (e.g. from a source file's final newline) would otherwise stay attached
// and make a single-node meta paragraph look like a two-node one.
#let split-paragraphs(nodes) = {
  let paras = ()
  let cur = ()
  for nd in nodes {
    if nd.func() == parbreak {
      if cur.len() > 0 {
        let trimmed = trim-trailing-seps(cur)
        if trimmed.len() > 0 { paras.push(trimmed) }
      }
      cur = ()
    } else if not (cur.len() == 0 and is-sep-func(nd.func())) {
      cur.push(nd)
    }
  }
  if cur.len() > 0 {
    let trimmed = trim-trailing-seps(cur)
    if trimmed.len() > 0 { paras.push(trimmed) }
  }
  paras
}

// Get a content value's children, treating a lone non-sequence node as a
// single-element list (top-level element function values like `sequence`
// aren't bindable identifiers in Typst, so this is checked structurally).
#let get-children(c) = if c.has("children") { c.children } else { (c,) }

// ---------------------------------------------------------------------
// Drawn decoration (design-cyber.md §4.5) — vector paths only, wrapped as
// pdf.artifact so they contribute zero characters to the text stream.
// ---------------------------------------------------------------------

// Prompt chevron: two 0.6pt strokes meeting at a point, one monospace cell.
#let draw-chevron(color, cell: 8.4pt) = artifact({
  let w = cell * 0.5
  let h = cell * 0.55
  box(width: cell, height: h, baseline: h * 0.28)[
    #place(line(start: (0pt, 0pt), end: (w, h / 2), stroke: 0.6pt + color))
    #place(line(start: (0pt, h), end: (w, h / 2), stroke: 0.6pt + color))
  ]
})

// Block cursor: filled rect, 0.6em × 0.7em, relative to the ambient text
// size at the call site (callers invoke this right after setting the text
// size for the line the cursor sits on).
#let draw-cursor(color) = artifact(
  box(width: 0.6em, height: 0.7em, fill: color)
)

// Horizontal rule, full column width.
#let draw-rule(color, weight) = artifact(
  line(length: 100%, stroke: weight + color)
)

// ---------------------------------------------------------------------
// Closed section-name vocabulary (design-cyber.md §7.2)
// ---------------------------------------------------------------------

#let section-vocab = (
  "SUMMARY": ("SUMMARY", "PROFESSIONAL SUMMARY"),
  "EXPERIENCE": ("EXPERIENCE", "WORK EXPERIENCE", "PROFESSIONAL EXPERIENCE"),
  "PROJECTS": ("PROJECTS", "PERSONAL PROJECTS", "OPEN SOURCE PROJECTS"),
  "SKILLS": ("SKILLS", "TECHNICAL SKILLS"),
  "EDUCATION": ("EDUCATION",),
  "CERTIFICATIONS": ("CERTIFICATIONS",),
  "PUBLICATIONS": ("PUBLICATIONS",),
  "LANGUAGES": ("LANGUAGES",),
)

// Sections that split into H2 entries; the rest render directly.
#let entry-sections = ("EXPERIENCE", "PROJECTS", "EDUCATION", "CERTIFICATIONS", "PUBLICATIONS")

#let validate-section(raw-name) = {
  let upper = upper(raw-name.trim())
  for (canonical, variants) in section-vocab.pairs() {
    if variants.contains(upper) {
      return (canonical: canonical, rendered: upper)
    }
  }
  panic(
    "Unknown section heading \"" + raw-name.trim() + "\". "
    + "Section names must come from the closed vocabulary in "
    + "design-cyber.md §7.2 (SUMMARY, EXPERIENCE, PROJECTS, SKILLS, "
    + "EDUCATION, CERTIFICATIONS, PUBLICATIONS, LANGUAGES, or a documented "
    + "variant)."
  )
}

// ---------------------------------------------------------------------
// Section header rendering
// ---------------------------------------------------------------------

#let render-section-header(rendered, color, font-chrome, scope) = {
  block(above: spacing-section-to-section, below: 0pt, breakable: false)[
    #place(left, dx: -9mm, dy: 0.05em)[#draw-chevron(color)]
    #heading(level: 1, bookmarked: true)[
      #set text(font: font-chrome, size: size-section-header, tracking: 0.08em, weight: "bold")
      #if scope == "first3" and rendered.len() > 3 {
        text(fill: color, rendered.slice(0, 3)) + text(fill: fg, rendered.slice(3))
      } else {
        text(fill: color, rendered)
      }
    ]
  ]
  v(spacing-section-header-to-rule)
  draw-rule(color, 0.6pt)
  v(spacing-rule-to-content)
}

// ---------------------------------------------------------------------
// Meta-line (org | location) extraction from an emph node, pulling out a
// leading logo image if present (mvp spec §5).
// ---------------------------------------------------------------------

#let extract-meta(emph-node) = {
  let inner = emph-node.body
  let parts = get-children(inner)
  let logo-source = none
  let text-parts = ()
  for p in parts {
    if logo-source == none and p.func() == box and p.body.func() == image {
      logo-source = p.body.source
    } else {
      text-parts.push(p)
    }
  }
  let text = flatten-text(join-content(text-parts)).trim()
  let (org, location) = split-last(text, "|")
  // Alt text is auto-derived from the org name, never the markdown alt
  // attribute, which stays empty by convention (mvp spec §5, §11).
  //
  // logo-source is written project-root-relative *without* a leading "/"
  // in content (Pandoc's own PDF-production preprocessing fetches every
  // image itself before the compiled source ever reaches Typst, treating
  // a leading "/" as an OS-filesystem-absolute path rather than a
  // project-root path — a bare relative reference, resolved against
  // Pandoc's CWD, is what survives that step). This image(...) call sits
  // in package code, though, so it needs a leading "/" to resolve against
  // the package root rather than src/'s own directory — prepend it here.
  let logo = if logo-source != none {
    let abs-source = if logo-source.starts-with("/") { logo-source } else { "/" + logo-source }
    image(abs-source, alt: org, height: 11pt)
  } else { none }
  (logo: logo, org: org, location: location)
}

// ---------------------------------------------------------------------
// Bullet + master-comment rendering (mvp spec §5, §10)
// ---------------------------------------------------------------------

#let strip-trailing-quote(body) = {
  let kids = get-children(body)
  let last = kids.len() - 1
  while last >= 0 and is-sep-func(kids.at(last).func()) {
    last -= 1
  }
  if last >= 0 and kids.at(last).func() == quote {
    let q = kids.at(last)
    let clean = kids.slice(0, last)
    while clean.len() > 0 and is-sep-func(clean.last().func()) {
      clean = clean.slice(0, clean.len() - 1)
    }
    (join-content(clean), q)
  } else {
    (body, none)
  }
}

#let render-bullets(items, font-body, master) = {
  for it in items {
    let (clean-body, comment) = strip-trailing-quote(it.body)
    let show-comment = comment != none and master
    block(above: 0pt, below: if show-comment { spacing-bullet-to-comment } else { spacing-bullet-to-bullet })[
      #list(list.item(clean-body))
    ]
    if show-comment {
      block(above: 0pt, below: spacing-bullet-to-bullet, inset: (left: 1.2em))[
        #set text(size: size-comment, fill: comment-tint, font: font-body)
        #set par(leading: 0.45em)
        #comment.body
      ]
    }
  }
}

// ---------------------------------------------------------------------
// One CV entry: meta line, optional tagline paragraphs, bullets (with
// optional master comments), optional trailing tech line.
// ---------------------------------------------------------------------

#let render-entry(children, title, date, font-body, font-chrome, master, logos) = {
  let i = 0
  let n = children.len()
  let inline-run = ()
  let items = ()
  let tech = none

  while i < n {
    let f = children.at(i).func()
    if f == list.item {
      items.push(children.at(i))
      i += 1
    } else if f == raw and not children.at(i).block {
      tech = children.at(i)
      i += 1
    } else {
      inline-run.push(children.at(i))
      i += 1
    }
  }

  let paras = split-paragraphs(inline-run)

  let meta = none
  let extra-start = 0
  if paras.len() > 0 and paras.at(0).len() == 1 and paras.at(0).at(0).func() == emph {
    meta = extract-meta(paras.at(0).at(0))
    extra-start = 1
  }

  let has-logo-col = logos and meta != none
  block(
    above: 0pt,
    below: if meta != none { spacing-meta-to-tagline } else { spacing-title-to-meta },
  )[
    #if has-logo-col {
      place(left + horizon)[
        #box(width: width-entry-logo-box, height: height-entry-logo-box)[
          #if meta.logo != none { align(left, meta.logo) }
        ]
      ]
    }
    #pad(left: if has-logo-col { width-entry-logo-gutter } else { 0pt })[
      #heading(level: 2)[
        #set text(font: font-body, size: size-entry-title, weight: "semibold", fill: fg)
        #title
        #if date != none {
          h(1fr)
          set text(font: font-chrome, size: size-entry-date, weight: "regular", fill: muted)
          date
        }
      ]
      #if meta != none {
        v(spacing-title-to-meta)
        set text(font: font-body, size: size-meta, style: "italic")
        meta.org
        if meta.location != none {
          h(1fr)
          meta.location
        }
      }
    ]
  ]

  for para in paras.slice(extra-start) {
    block(above: 0pt, below: spacing-tagline-to-bullets)[
      #set text(font: font-body, size: size-body)
      #join-content(para)
    ]
  }

  if items.len() > 0 {
    render-bullets(items, font-body, master)
  }

  if tech != none {
    block(above: spacing-to-tech-line, below: 0pt, inset: (left: inset-tech-line))[
      #set text(font: font-chrome, size: size-tech, fill: muted)
      #tech.text
    ]
  }
}

// ---------------------------------------------------------------------
// Skills row (mvp spec §6.6-equivalent, §5 definition-list rule) — a
// single line of text, never a table/grid.
// ---------------------------------------------------------------------

// Renders as a single line of real text — an inline monospace label padded
// with literal space characters to a fixed column width, never a
// table/grid (design-cyber.md §6.6). Padding with actual space characters
// (rather than a wide `box(width:)` gutter) also sidesteps a real
// extraction hazard: several PDF text extractors — pymupdf's default plain
// -text mode included, confirmed empirically — insert a spurious line
// break when a `box`'s reserved width leaves a large glyph-free gap on the
// line, even though the glyphs sit at the same baseline.
#let render-skills-row(term-node, desc-node, pad-to, font-chrome, font-body, color) = {
  // Pandoc wraps a Markdown definition-list description in
  // `#block[\n...\n]`; the leading/trailing newlines parse as space nodes,
  // which flatten-text (deliberately) doesn't trim on its own — trim here
  // so the two workflows extract identical padding/text (mvp spec cross-
  // workflow parity).
  let label = flatten-text(term-node).trim()
  let padded = label + " " * calc.max(2, pad-to - label.len() + 2)
  block(above: 0pt, below: spacing-skills-row-to-row)[
    #set text(font: font-chrome, size: size-skills-label, weight: "medium", fill: color)
    #padded
    #set text(font: font-body, size: size-body, weight: "regular", fill: fg)
    #flatten-text(desc-node).trim()
  ]
}

// ---------------------------------------------------------------------
// Header block (mvp spec §4.2, design-cyber.md §6.3)
// ---------------------------------------------------------------------

#let render-header(name, tagline, email, phone, location, links, font-chrome, font-body, color, icons) = {
  block(above: 0pt, below: spacing-section-to-section)[
    #block(above: 0pt, below: spacing-header-internal)[
      #set text(font: font-chrome, size: size-name, weight: "bold", tracking: 0.04em, fill: fg)
      #upper(name)
      #h(0.15em)
      #box(baseline: 0.05em)[#draw-cursor(color)]
    ]
    #block(above: 0pt, below: spacing-header-internal)[
      #set text(font: font-body, size: size-tagline, fill: muted)
      #tagline
    ]
    #block(above: 0pt, below: if links.len() > 0 { spacing-header-internal } else { spacing-header-to-rule })[
      #set text(font: font-chrome, size: size-contact, fill: fg)
      #let contact-parts = (
        (icons.at("email", default: none), email, "mailto:" + email),
        (icons.at("phone", default: none), phone, none),
        (icons.at("location", default: none), location, none),
      ).filter(p => p.at(1) != none and p.at(1) != "")
      #for (idx, p) in contact-parts.enumerate() {
        let (ic, value, link-target) = p
        if idx > 0 { [ · ] }
        if ic != none { ic; h(2pt) }
        if link-target != none { link(link-target)[#value] } else { value }
      }
    ]
    #if links.len() > 0 [
      #block(above: 0pt, below: spacing-header-to-rule)[
        #set text(font: font-chrome, size: size-contact, fill: fg)
        #for (idx, l) in links.enumerate() {
          if idx > 0 { [ · ] }
          link("https://" + l)[#l]
        }
      ]
    ]
    #draw-rule(color, 1.2pt)
  ]
}

// ---------------------------------------------------------------------
// Top-level CV template function
// ---------------------------------------------------------------------

#let cv(
  name: "",
  tagline: "",
  email: "",
  phone: "",
  location: "",
  links: (),
  paper: "a4",
  accent: "green",
  accent-scope: "full",
  font-chrome: "IBM Plex Mono",
  font-body: "IBM Plex Sans",
  icons: false,
  logos: false,
  master: false,
  body,
) = {
  let name = flatten-text(name)
  let tagline = flatten-text(tagline)
  let email = flatten-text(email)
  let phone = flatten-text(phone)
  let location = flatten-text(location)

  let geo = page-geometry.at(paper)
  let accent-value = effective-accent(resolve-accent(accent))

  set-metadata(name: name, tagline: tagline, doc-kind: "CV")
  set page(paper: geo.paper, margin: geo.margin)
  set text(font: font-body, size: size-body, fill: fg, ligatures: false, lang: "en")
  // mvp spec §4.2's "leading 1.35" is a CSS-style line-height multiplier
  // (total line box / font size); Typst's `leading` is the *extra* gap on
  // top of the font's own metrics, a different quantity. 0.5em lands close
  // to the intended visual density without the units mismatch.
  set par(justify: false, leading: 0.5em)
  set heading(numbering: none, outlined: true)
  // Every heading's vertical gap is driven exclusively by an explicit
  // wrapping block at its call site (render-section-header for H1, the H2
  // entry-title wrapper below) — zeroing Typst's own level-dependent
  // heading spacing here keeps the named scale in theme.typ the single
  // source of truth for vertical rhythm.
  show heading: set block(above: 0pt, below: 0pt, sticky: true)

  let icon-map = if icons {
    (
      email: icon("email"),
      phone: icon("phone"),
      location: icon("location"),
    )
  } else {
    (:)
  }

  render-header(name, tagline, email, phone, location, links, font-chrome, font-body,
    accent-for(accent-value, 0), icon-map)

  // ---- Split into sections at H1 boundaries, validate vocabulary ----
  let children = body.children
  let n = children.len()
  let i = 0
  let section-index = 0

  while i < n {
    let f = children.at(i).func()
    if f == heading and children.at(i).depth == 1 {
      let sec = validate-section(flatten-text(children.at(i).body))
      let color = accent-for(accent-value, section-index)
      section-index += 1
      i += 1

      // Gather this section's children up to the next H1.
      let sec-start = i
      while i < n and not (children.at(i).func() == heading and children.at(i).depth == 1) {
        i += 1
      }
      let sec-children = children.slice(sec-start, i)

      render-section-header(sec.rendered, color, font-chrome, accent-scope)

      if entry-sections.contains(sec.canonical) {
        // Split into entries at H2 boundaries.
        let j = 0
        let m = sec-children.len()
        let first-entry = true
        while j < m {
          if sec-children.at(j).func() == heading and sec-children.at(j).depth == 2 {
            if not first-entry { v(spacing-entry-to-entry) }
            first-entry = false
            let (title, date) = split-last(flatten-text(sec-children.at(j).body), "|")
            j += 1
            let entry-start = j
            while j < m and not (sec-children.at(j).func() == heading and sec-children.at(j).depth == 2) {
              j += 1
            }
            render-entry(sec-children.slice(entry-start, j), title, date, font-body, font-chrome, master, logos)
          } else {
            j += 1
          }
        }
      } else if sec.canonical == "SKILLS" {
        let rows = sec-children.filter(c => c.func() == terms.item)
        let pad-to = rows.map(c => flatten-text(c.term).trim().len()).fold(0, calc.max)
        for c in rows {
          render-skills-row(c.term, c.description, pad-to, font-chrome, font-body, color)
        }
      } else {
        // SUMMARY, LANGUAGES, or anything else without H2 entries:
        // render the section's inline content directly.
        for para in split-paragraphs(sec-children) {
          block(above: 0pt, below: spacing-tagline-to-bullets)[#join-content(para)]
        }
      }
    } else {
      i += 1
    }
  }
}
