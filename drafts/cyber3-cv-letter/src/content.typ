// Generic content-tree helpers. No CV-specific knowledge lives here.

// Flattens a content tree to its plain-text representation.
#let flatten-text(node) = {
  if type(node) == str {
    node
  } else if node.func() == text {
    node.at("text")
  } else if node.has("children") {
    node.children.map(flatten-text).join("")
  } else if node.has("body") {
    flatten-text(node.at("body"))
  } else if repr(node.func()) == "space" {
    " "
  } else if node.has("text") {
    str(node.at("text"))
  } else {
    ""
  }
}

// Splits on the *last* occurrence of `sep`, trimming both sides. Second
// element is `none` if `sep` isn't present. Splitting on the last (not
// first) occurrence guards against a title/org value that itself contains
// `sep`.
#let split-last(s, sep) = {
  if sep in s {
    let parts = s.split(sep)
    (parts.slice(0, -1).join(sep).trim(), parts.last().trim())
  } else {
    (s.trim(), none)
  }
}

// Joins a list of content pieces into one content value.
#let join-content(pieces) = pieces.fold([], (acc, p) => acc + p)

// Returns the direct children of a content node — its `children` sequence
// if it has one, its unwrapped `body` if it has one, or a single-element
// array wrapping the node itself if it's already a leaf (e.g. a lone
// `text` node, which has neither field).
#let get-children(node) = {
  if node.has("children") {
    node.children
  } else if node.has("body") {
    get-children(node.at("body"))
  } else {
    (node,)
  }
}

// Splits a flat list of block-level content nodes into paragraph groups —
// the nodes between successive `parbreak`s.
#let split-paragraphs(nodes) = {
  let groups = ()
  let current = ()
  for node in nodes {
    if node.func() == parbreak {
      if current.len() > 0 { groups.push(current) }
      current = ()
    } else {
      current.push(node)
    }
  }
  if current.len() > 0 { groups.push(current) }
  groups
}
