// cv-letter() — spec/20260828-mvp.md §11.4, design-cyber Appendix A.
// Reuses cv-resume()'s header component and theme resolution so the pair
// reads as one system (§7, rev-modern-cv R4.6) — no separate header logic.

#import "tokens.typ": *
#import "marks.typ"
#import "markup.typ"
#import "resume.typ": header-block, footer-block

#let cv-letter(
  author: (:),
  accent: "green",
  accent-scope: "full",
  variant: "themed",
  paper-size: "a4",
  margins: none,
  font: "IBM Plex Sans",
  header-font: "IBM Plex Mono",
  show-footer: false,
  date: none,
  keywords: (),
  body,
) = {
  assert("name" in author, message: "cv-letter: author.name is required")
  let author = sanitize-author(author)
  assert(date != none, message: "cv-letter: date is required (long form, e.g. \"28 August 2026\")")

  let show-marks = variant == "themed"
  let accent-list = if variant == "plain" { (fg,) } else { markup.resolve-accent(accent) }
  let geometry = page-geometry.at(paper-size)
  let m = if margins != none { margins } else { (top: geometry.top, bottom: geometry.bottom, left: geometry.left, right: geometry.right) }

  set document(
    title: author.name + " — Cover Letter",
    author: author.name,
    keywords: keywords,
  )
  set text(lang: "en")
  set page(paper: geometry.paper, margin: m, footer: if show-footer { footer-block(author, header-font, show-marks) } else { none })

  let bf = resolve-font(font, weight: type-scale.body.weight)
  set text(font: bf.family, weight: bf.weight, size: type-scale.body.size, fill: fg, lang: "en")
  set par(justify: false, leading: 1.35em, spacing: space-letter-paragraph)

  header-block(author, accent-list.at(0), font, header-font, false, show-marks)

  // Date line, marked with the drawn prompt chevron — the letter's one
  // header-like line (design-cyber Appendix A).
  let df = resolve-font(header-font, weight: type-scale.dates.weight)
  block(above: 0pt, below: space-section, {
    if show-marks {
      place(dx: -mark-gutter, marks.chevron(accent-list.at(0), header-font, type-scale.body.size))
    }
    text(font: df.family, weight: df.weight, size: type-scale.dates.size, fill: muted)[#date]
  })

  [Dear Hiring Manager,]
  v(space-letter-paragraph)

  body

  v(space-letter-paragraph)
  [Best regards,]
  parbreak()
  [#author.name]
}
