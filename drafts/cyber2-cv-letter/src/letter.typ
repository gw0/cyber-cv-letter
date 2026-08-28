// Cover letter template entry point (mvp spec §5 header parity,
// design-cyber.md Appendix A).

#import "theme.typ": *
#import "ats.typ": set-metadata
#import "layout.typ": render-header, draw-chevron, draw-cursor, flatten-text, join-content, split-paragraphs

#let cover-letter(
  name: "",
  tagline: "",
  email: "",
  phone: "",
  location: "",
  links: (),
  date: "",
  paper: "a4",
  accent: "green",
  font-chrome: "IBM Plex Mono",
  font-body: "IBM Plex Sans",
  footer: true,
  body,
) = {
  let name = flatten-text(name)
  let tagline = flatten-text(tagline)
  let email = flatten-text(email)
  let phone = flatten-text(phone)
  let location = flatten-text(location)

  let geo = page-geometry.at(paper)
  let accent-value = effective-accent(resolve-accent(accent))
  let color = accent-for(accent-value, 0)

  set-metadata(name: name, tagline: tagline, doc-kind: "Cover Letter")
  set page(paper: geo.paper, margin: geo.margin)
  set text(font: font-body, size: size-body, fill: fg, ligatures: false, lang: "en")
  set par(justify: false, leading: 0.5em)

  render-header(name, tagline, email, phone, location, links, font-chrome, font-body, color, (:))

  block(above: spacing-section-to-section, below: spacing-letter-paragraph)[
    #box(width: 8.4pt, height: 1em)[#draw-chevron(color)]
    #h(4pt)
    #set text(font: font-chrome, size: size-meta, fill: fg)
    #date
  ]

  // Body: a sequence of plain paragraphs (salutation, prose, signature),
  // separated by blank lines in the source. Rendered as-is — the letter is
  // free-form prose, not pattern-matched like a CV entry.
  for para in split-paragraphs(body.children) {
    block(above: 0pt, below: spacing-letter-paragraph)[#join-content(para)]
  }

  if footer {
    place(bottom + left, dy: -8pt)[
      #set text(font: font-chrome, size: size-footer, fill: muted)
      #(lower(name).replace(" ", ".") + "@ena:~$ ")
      #box(baseline: 0.15em)[#draw-cursor(color)]
    ]
  }
}
