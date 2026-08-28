// Icon loading + filename-derived alt text (mvp spec §9).
//
// Convention: icons/<set>/<semantic-name>.png. Alt text is the filename
// without extension, i.e. the semantic key itself.

#let icon-set = "/icons/fontawesome"

// Boxed so the image flows inline with surrounding text instead of
// forcing a block-level line of its own.
#let icon(name, height: 8pt) = box(
  height: height, baseline: 0.15em,
  image(icon-set + "/" + name + ".png", height: height, alt: name)
)
