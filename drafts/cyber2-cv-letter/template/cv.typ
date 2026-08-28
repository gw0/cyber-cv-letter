// Typst template entry point for a CV, consumed by Pandoc's "--template"
// flag on the Markdown-via-Pandoc build path (mvp spec section 12). Front
// matter becomes Pandoc template variables here; the Markdown body below
// (substituted by Pandoc) is emitted through Pandoc's typst writer using
// the same standard elements (heading, emph, paragraph, list, quote,
// image) the hand-authored examples use directly, so cv() processes both
// identically.
//
// Identity fields are passed as bracketed Typst content, not quoted
// strings: Pandoc's typst writer escapes Typst-special characters (@ # _
// * ...) when it renders text as markup, and that escaping only survives
// correctly inside markup (content), not inside a quoted string literal's
// more limited escape grammar. cv() flattens these back to plain text
// internally. accent/accent-scope/icons/logos read from `sys.inputs`
// first — the only fields a build-time preset (e.g. friggeri) overrides —
// falling back to the front-matter value.
//
// NOTE: this file is a Pandoc template, not plain Typst — Pandoc replaces
// any "dollar-name-dollar" token anywhere in the file, comments included,
// so none may appear outside the substitution block below.
#import "@local/hacker-cv:0.1.0": cv

#show: cv.with(
  name: [$name$],
  tagline: [$tagline$],
  email: [$email$],
  phone: [$phone$],
  location: [$location$],
  links: ($for(links)$"$links$",$endfor$),
  paper: "$paper$",
  font-chrome: "$font-chrome$",
  font-body: "$font-body$",
  master: $if(master)$true$else$false$endif$,
  accent: sys.inputs.at("accent", default: "$accent$"),
  accent-scope: sys.inputs.at("accent-scope", default: "$accent-scope$"),
  icons: sys.inputs.at("icons", default: "$if(icons)$true$else$false$endif$") == "true",
  logos: sys.inputs.at("logos", default: "$if(logos)$true$else$false$endif$") == "true",
)

$body$
