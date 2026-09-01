// cv-resume() — document-level setup only (spec/20260828-mvp.md §11.3).
// Author identity, accent, variant, paper size, margins, feature toggles.
// Never called per-entry — entry rendering lives entirely in markup.typ.

#import "tokens.typ": *
#import "marks.typ"
#import "markup.typ"

// Relative to this file's own location (src/resume.typ), not to whatever
// --root the compiling workflow uses — a leading "/" would mean "project
// root" under direct Typst (--root .) but "OS root" under the Pandoc
// workflow (--root /, required for Pandoc's extracted media images), so it
// can't resolve correctly under both. A plain relative path is anchored to
// this file's own on-disk location regardless of which workflow imported
// it (same reasoning as lib.typ's own `#import "src/resume.typ"`).
#let icon-for(kind) = "../icons/fontawesome/" + (
  if kind == "email" { "fa-envelope-square.png" }
  else if kind == "phone" { "fa-phone-square.png" }
  else if kind == "location" { "fa-map-marker.png" }
  else if kind == "github.com" { "fa-github-square.png" }
  else if kind == "linkedin.com" { "fa-linkedin-square.png" }
  else { "fa-link.png" }
)

#let icon-image(kind, alt) = box(width: 9pt, height: 9pt, baseline: 1.5pt,
  image(icon-for(kind), width: 9pt, height: 9pt, alt: alt))

// Shared header component — used unmodified by both cv-resume() and
// cv-letter() (§7: "identical geometry and tokens... so the pair reads as
// one system"; rev-modern-cv R4.6).
#let header-block(author, accent-color, font, header-font, show-icons, show-marks) = {
  let nf = resolve-font(header-font, weight: type-scale.name.weight)
  let tf = resolve-font(font, weight: type-scale.tagline.weight)
  let cf = resolve-font(header-font, weight: type-scale.contact.weight)

  // below: space-header-to-section (not a following v()) so this gap
  // collapses with whatever comes next like every other seam in the
  // document, instead of adding to it — see the spacing-convention note in
  // tokens.typ.
  block(above: 0pt, below: space-header-to-section, {
    let lines = ()

    // Line 1 — name, always first (design-cyber §6.3's hardest rule).
    lines.push({
      text(font: nf.family, weight: nf.weight, size: type-scale.name.size, tracking: 0.04em, fill: fg)[#upper(author.name)]
      if show-marks {
        h(0.3em)
        marks.cursor(accent-color, header-font, type-scale.name.size)
      }
    })

    // Line 2 — tagline.
    if "tagline" in author {
      lines.push(text(font: tf.family, weight: tf.weight, size: type-scale.tagline.size, fill: muted)[#author.tagline])
    }

    // Line 3 — contact: email · location · phone.
    let contact-items = ()
    if "email" in author {
      let node = link("mailto:" + author.email)[#author.email]
      contact-items.push(if show-icons { icon-image("email", "email") + h(3pt) + node } else { node })
    }
    if "location" in author {
      let node = [#author.location]
      contact-items.push(if show-icons { icon-image("location", "location") + h(3pt) + node } else { node })
    }
    if "phone" in author {
      let node = link("tel:" + author.phone)[#author.phone]
      contact-items.push(if show-icons { icon-image("phone", "phone") + h(3pt) + node } else { node })
    }
    if contact-items.len() > 0 {
      lines.push(text(font: cf.family, weight: cf.weight, size: type-scale.contact.size, fill: fg)[
        #contact-items.join([ #h(1pt)·#h(1pt) ])
      ])
    }

    // Line 4 — links, bare (no scheme), hyperlinked.
    if "links" in author and author.links.len() > 0 {
      let link-items = author.links.map(url => {
        let kind = if "github.com" in url { "github.com" } else if "linkedin.com" in url { "linkedin.com" } else { "link" }
        let node = link("https://" + url)[#url]
        if show-icons { icon-image(kind, kind) + h(3pt) + node } else { node }
      })
      lines.push(text(font: cf.family, weight: cf.weight, size: type-scale.contact.size, fill: fg)[
        #link-items.join([ #h(1pt)·#h(1pt) ])
      ])
    }

    // Same spacing/pattern as markup.typ's entry title↔meta stack
    // (header-stack) — see space-header-line's definition in tokens.typ.
    stack(dir: ttb, spacing: space-header-line, ..lines)

    v(space-section-to-rule)
    marks.rule(accent-color, weight: 1.2pt)
  })
}

// Decorative footer (design-cyber §6.8) — optional, off by default,
// nothing that matters (a page number is cosmetic, not content). The
// prompt's username@host is derived from the author record rather than
// hardcoded, so the shell-prompt flavour text is actually this document's.
#let footer-prompt-id(author) = {
  let user = lower(author.name.split(" ").first())
  let host = if "links" in author and author.links.len() > 0 {
    author.links.first().split("/").first()
  } else {
    "cv"
  }
  user + "@" + host
}

#let footer-block(author, header-font, show-marks) = context {
  let ff = resolve-font(header-font, weight: type-scale.footer.weight)
  set text(font: ff.family, weight: ff.weight, size: type-scale.footer.size, fill: muted)
  let id = footer-prompt-id(author)
  let prompt = if show-marks {
    [#id:~\$ #h(0.2em) #marks.cursor(muted, header-font, type-scale.footer.size)]
  } else {
    [#id:~\$]
  }
  grid(columns: (1fr, auto),
    prompt,
    [page #counter(page).display() / #context counter(page).final().at(0)],
  )
}

#let cv-resume(
  author: (:),
  accent: "green",
  accent-scope: "full",
  variant: "themed",
  paper-size: "a4",
  margins: none,
  font: "IBM Plex Sans",
  header-font: "IBM Plex Mono",
  show-logos: false,
  show-icons: false,
  show-footer: false,
  keywords: (),
  body,
) = {
  assert("name" in author, message: "cv-resume: author.name is required")
  let author = sanitize-author(author)

  let show-marks = variant == "themed"
  let accent-list = if variant == "plain" { (fg,) } else { markup.resolve-accent(accent) }
  let geometry = page-geometry.at(paper-size)
  let m = if margins != none { margins } else { (top: geometry.top, bottom: geometry.bottom, left: geometry.left, right: geometry.right) }

  set document(
    title: author.name + " — " + author.at("tagline", default: "CV"),
    author: author.name,
    keywords: keywords,
  )
  set text(lang: "en")
  set page(paper: geometry.paper, margin: m, footer: if show-footer { footer-block(author, header-font, show-marks) } else { none })

  let bf = resolve-font(font, weight: type-scale.body.weight)
  set text(font: bf.family, weight: bf.weight, size: type-scale.body.size, fill: fg, lang: "en")
  // Tightened below Typst's own 0.65em par-leading default (empirically,
  // see git history — the original "huge gap between wrapped lines" bug was
  // a larger custom value here, not this default). Stays in `em`, not on
  // tokens.typ's `u` grid: `u` exists to stop the *same* token silently
  // resolving to different physical lengths across independent call sites
  // (tokens.typ:68-75's body-indent/tech-line-pad example). `leading` has
  // only one call site, document-wide, and always resolves against the one
  // ambient body-text size this `set par` already sits under — and unlike
  // block-to-block gaps, line-height is conventionally font-size-relative
  // so it tracks body size if that ever changes, rather than needing to be
  // decoupled from it.
  set par(justify: false, leading: 0.6em, spacing: space-paragraph)
  // list's own `spacing:` is bullet-to-bullet only — the gap above/below
  // the whole list still comes from `par`'s `spacing:` above, unchanged
  // (tokens.typ's space-bullet comment explains why these are split).
  set list(marker: [•], indent: 0pt, body-indent: body-indent, spacing: space-bullet)

  show heading.where(level: 1): markup.section-heading-rule(accent-list, accent-scope, header-font, draw-marks: show-marks)
  show raw: markup.tech-line-rule(header-font, font)
  show quote: markup.comment-rule(font)

  header-block(author, accent-list.at(0), font, header-font, show-icons, show-marks)
  // The skills label column's width must be measured before any terms.item
  // is shown (markup.skills-label-width's comment explains why a per-row
  // query() from inside the show rule itself can't resolve) — computed
  // here, in the one `context` that wraps both the show-rule setup and the
  // render-body call it applies to.
  context {
    show terms.item: markup.skills-row-rule(font, header-font, accent-list, markup.skills-label-width(body, font, header-font))
    markup.render-body(body, font: font, header-font: header-font, show-logos: show-logos, accent-list: accent-list)
  }
}
