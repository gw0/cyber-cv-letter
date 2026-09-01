// Pandoc --template target for cv(). Identity fields are interpolated as
// content ([$email$]), never quoted strings ("$email$") — Pandoc's own
// markup-escaping runs on interpolated values assuming they land inside
// markup, not inside a quoted string literal's more limited escape
// grammar. Content interpolation sidesteps that mismatch entirely; cv()
// flattens these back to plain text internally where a plain string is
// needed (PDF metadata, footer prompt).
//
// This is the dev/CI copy — imports @local/cyber-cv-letter:0.1.0, resolved
// via --package-path .typst-packages. A copy distributed for external/
// published use would import @preview/cyber-cv-letter:<version> instead.
#import "@local/cyber-cv-letter:0.1.0": cv

#show: cv.with(
  author: (
    name: [$name$],
$if(tagline)$    tagline: [$tagline$],
$endif$$if(email)$    email: [$email$],
$endif$$if(location)$    location: [$location$],
$endif$$if(phone)$    phone: [$phone$],
$endif$$if(links)$    links: ($for(links)$[$links$],$endfor$),
$endif$  ),
  accent: sys.inputs.at("accent", default: "$accent$"),
  accent-scope: sys.inputs.at("accent-scope", default: "$accent-scope$"),
  variant: sys.inputs.at("variant", default: "$variant$"),
  paper: "$paper$",
  show-logos: sys.inputs.at("show-logos", default: "$if(show-logos)$true$else$false$endif$") == "true",
  show-icons: sys.inputs.at("show-icons", default: "$if(show-icons)$true$else$false$endif$") == "true",
  show-footer: sys.inputs.at("show-footer", default: "$if(show-footer)$true$else$false$endif$") == "true",
  show-notes: sys.inputs.at("show-notes", default: "$if(show-notes)$true$else$false$endif$") == "true",
)

$body$
