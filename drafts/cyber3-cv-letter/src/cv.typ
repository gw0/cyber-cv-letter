// Page setup, header/footer rendering, and the top-level cv().

#import "theme.typ": fg, muted, resolve-font, resolve-accent, page-geometry, space-header-line, space-section-to-rule, space-paragraph
#import "marks.typ": draw-cursor, draw-rule
#import "fonts.typ": default-font-chrome, default-font-body
#import "icons.typ": icon-path, icon-for-link, icon-kind-for-link
#import "content.typ": flatten-text
#import "ats.typ": set-metadata
#import "entries.typ": render-cv-body

// `none`-safe flatten-text: identity fields are optional, and Pandoc omits
// an absent field's key entirely rather than passing an empty value.
#let text-of(v) = if v == none { none } else { flatten-text(v) }

// Gap before the cursor mark, em-relative to whatever text precedes it (the
// 20pt name line, the 8pt footer prompt) — retuned up from the cursor's own
// original 0.2em, which kept an identical ratio to the cursor's (also
// em-relative) 0.6em width at both call sites, but whose absolute gap in
// the footer (1.6pt) read as visibly narrower than the header's (4pt)
// despite the equal ratio. 0.3em keeps the gap proportional to its own
// local text size at each call site, while being generous enough that the
// footer's small absolute size (2.4pt) no longer reads as cramped.
#let cursor-gap = 0.3em

#let header-block(author, color, font-chrome, font-body, show-icons, show-marks) = {
  let name-line = {
    set text(..resolve-font(font-chrome, weight: "bold"), size: 20pt, fill: fg)
    author.name
    if show-marks { h(cursor-gap); draw-cursor(color) }
  }

  let tagline-line = if author.at("tagline", default: none) != none {
    block(above: 0pt, below: 0pt, {
      set text(..resolve-font(font-body, weight: "regular"), size: 10.5pt, fill: muted)
      author.tagline
    })
  } else { none }

  let contact-parts = ()
  if author.at("email", default: none) != none { contact-parts.push(("email", author.email)) }
  if author.at("location", default: none) != none { contact-parts.push(("location", author.location)) }
  if author.at("phone", default: none) != none { contact-parts.push(("phone", author.phone)) }

  let contact-line = if contact-parts.len() > 0 {
    block(above: 0pt, below: 0pt, {
      set text(..resolve-font(font-chrome, weight: "regular"), size: 9pt, fill: fg)
      for (i, part) in contact-parts.enumerate() {
        if i > 0 { [ · ] }
        if show-icons { box(image(icon-path(part.at(0)), height: 9pt, alt: part.at(0)), baseline: 1pt); h(2pt) }
        part.at(1)
      }
    })
  } else { none }

  let links = author.at("links", default: ())
  let links-line = if links.len() > 0 {
    block(above: 0pt, below: 0pt, {
      set text(..resolve-font(font-chrome, weight: "regular"), size: 9pt, fill: fg)
      for (i, link) in links.enumerate() {
        if i > 0 { [ · ] }
        if show-icons {
          let url = flatten-text(link)
          box(image(icon-for-link(url), height: 9pt, alt: icon-kind-for-link(url)), baseline: 1pt)
          h(2pt)
        }
        link
      }
    })
  } else { none }

  let lines = (name-line, tagline-line, contact-line, links-line).filter(l => l != none)

  block(above: 0pt, below: 0pt, {
    stack(dir: ttb, spacing: space-header-line, ..lines)
    v(space-section-to-rule)
    draw-rule(color, weight: 1.2pt)
  })
}

#let footer-block(author, font-chrome, show-marks) = context {
  let prompt-id = if author.at("email", default: none) != none {
    flatten-text(author.email)
  } else {
    lower(flatten-text(author.name)).replace(" ", ".") + "@localhost"
  }
  set text(..resolve-font(font-chrome, weight: "regular"), size: 8pt, fill: muted)
  let prompt = prompt-id + ":~$"
  let page-num = str(counter(page).get().first())
  let total = str(counter(page).final().first())
  grid(
    columns: (1fr, 1fr),
    align(left, { prompt; if show-marks { h(cursor-gap); draw-cursor(muted) } }),
    align(right, page-num + " / " + total),
  )
}

#let cv(
  author: (:),
  accent: "red",
  accent-scope: "full",
  variant: "themed",
  paper: "a4",
  show-logos: false,
  show-icons: false,
  show-footer: false,
  show-notes: false,
  keywords: none,
  body,
) = {
  let accent-list = resolve-accent(accent)
  if variant == "plain" { accent-list = (fg,) }
  let show-marks = variant == "themed"

  let font-chrome = default-font-chrome
  let font-body = default-font-body

  let geo = page-geometry.at(paper)

  set-metadata(
    name: text-of(author.name),
    tagline: text-of(author.at("tagline", default: none)),
    doc-kind: "CV",
    keywords: keywords,
  )

  set page(
    paper: geo.paper,
    margin: geo.margin,
    footer: if show-footer { footer-block(author, font-chrome, show-marks) } else { none },
  )
  set text(font: font-body, size: 10.5pt, fill: fg, lang: "en")
  set par(justify: false, leading: 0.6em, spacing: space-paragraph)
  show heading: it => it.body
  set heading(numbering: none, outlined: true, bookmarked: true)

  header-block(author, accent-list.at(0), font-chrome, font-body, show-icons, show-marks)
  render-cv-body(body, accent-list, accent-scope, font-body, font-chrome, show-logos, show-notes)
}
