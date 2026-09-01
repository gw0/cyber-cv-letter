// letter() — reuses cv.typ's header component. No section vocabulary, no
// entry pairing: the body is plain paragraphs, laid out by the ambient
// par(spacing:) set rule with no manual content-tree walk needed.

#import "theme.typ": fg, resolve-font, resolve-accent, page-geometry, space-paragraph, mark-gutter
#import "marks.typ": draw-chevron
#import "fonts.typ": default-font-chrome, default-font-body
#import "ats.typ": set-metadata
#import "cv.typ": header-block, footer-block, text-of

#let letter(
  author: (:),
  accent: "red",
  accent-scope: "full",
  variant: "themed",
  paper: "a4",
  show-footer: false,
  show-icons: false,
  date: none,
  keywords: none,
  body,
) = {
  assert(date != none, message: "letter() requires date:")

  let accent-list = resolve-accent(accent)
  if variant == "plain" { accent-list = (fg,) }
  let show-marks = variant == "themed"
  let font-chrome = default-font-chrome
  let font-body = default-font-body
  let geo = page-geometry.at(paper)

  set-metadata(
    name: text-of(author.name),
    tagline: text-of(author.at("tagline", default: none)),
    doc-kind: "Cover Letter",
    keywords: keywords,
  )

  set page(
    paper: geo.paper,
    margin: geo.margin,
    footer: if show-footer { footer-block(author, font-chrome, show-marks) } else { none },
  )
  set text(font: font-body, size: 10.5pt, fill: fg, lang: "en")
  // leading re-tuned alongside the space-letter-paragraph -> space-paragraph
  // consolidation: the old 1.35em leading (~14.2pt) was comfortably under
  // the old 16pt paragraph gap, but reusing the CV's tighter space-paragraph
  // (8pt token, ~15.3pt measured block-to-block) would otherwise invert the
  // hierarchy — wrapped lines within one paragraph reading further apart
  // than the paragraphs themselves. 0.7em keeps the letter airier than the
  // CV body (0.6em) while staying under the paragraph gap.
  set par(justify: false, leading: 0.7em, spacing: space-paragraph)

  header-block(author, accent-list.at(0), font-chrome, font-body, show-icons, show-marks)

  block(above: space-paragraph, below: 0pt, breakable: false, {
    // dy re-measured empirically (pixel-scanned ink bounding boxes via
    // pymupdf) against the date line's actual vertical center at 9pt — the
    // prior 0.2em guess was ~3.3pt too low against this line's font/size.
    place(dx: -mark-gutter, dy: -1.175pt, draw-chevron(accent-list.at(0)))
    set text(..resolve-font(font-chrome, weight: "regular"), size: 9pt)
    date
  })

  block(above: space-paragraph, below: space-paragraph, [Dear Hiring Manager,])

  body

  block(above: space-paragraph, below: 0pt, {
    [Best regards,]
    linebreak()
    author.name
  })
}
