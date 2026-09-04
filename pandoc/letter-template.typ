// Pandoc --template target for letter(). Same content-interpolation
// rationale as cv-template.typ.
#import "@preview/cyber-cv-letter:0.1.0": letter

#show: letter.with(
  author: (
    name: [$name$],
$if(tagline)$    tagline: [$tagline$],
$endif$$if(email)$    email: [$email$],
$endif$$if(location)$    location: [$location$],
$endif$$if(phone)$    phone: [$phone$],
$endif$$if(links)$    links: ($for(links)$[$links$],$endfor$),
$endif$  ),
  accent: sys.inputs.at("accent", default: "$if(accent)$$accent$$else$red$endif$"),
  accent-scope: sys.inputs.at("accent-scope", default: "$if(accent-scope)$$accent-scope$$else$full$endif$"),
  paper: "$if(paper)$$paper$$else$a4$endif$",
  show-icons: sys.inputs.at("show-icons", default: "true") == "true",
  show-footer: sys.inputs.at("show-footer", default: "true") == "true",
$if(keywords)$  keywords: ($for(keywords)$[$keywords$],$endfor$),
$endif$  date: [$date$],
)

$body$
