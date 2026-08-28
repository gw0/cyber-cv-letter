// pdf.artifact wrapping helpers, PDF/UA-1 + metadata setup (mvp spec §11).

// Wrap a purely decorative element so it contributes zero characters to the
// text stream and is skipped by assistive tech. `kind` should be the most
// specific artifact kind available (design-cyber.md §8): "layout" for drawn
// rules/marks, "footer" for footer content.
#let artifact(body, kind: "layout") = pdf.artifact(kind: kind, body)

// Populate PDF metadata per mvp spec §11 / design-cyber.md §8.
//   title    = "<Name> — <Role> — <doc-kind>"
//   author   = full name
//   subject  = target role (tagline)
//   keywords = core tech keywords, derived from the tagline's `·`-separated
//              segments unless the caller supplies an explicit list.
#let set-metadata(name: none, tagline: none, doc-kind: "CV", keywords: none) = {
  let role = tagline
  let kw = if keywords != none {
    keywords
  } else if tagline != none {
    tagline.split("·").map(s => s.trim())
  } else {
    ()
  }
  set document(
    title: name + " — " + role + " — " + doc-kind,
    author: name,
    description: role, // PDF Subject = target role
    keywords: kw,
  )
}
