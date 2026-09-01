// Pandoc --template target for letter(). Same content-interpolation
// rationale as cv-template.typ.
#import "@local/cyber-cv-letter:0.1.0": letter

#show: letter.with(
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
  show-footer: sys.inputs.at("show-footer", default: "$if(show-footer)$true$else$false$endif$") == "true",
  show-icons: sys.inputs.at("show-icons", default: "$if(show-icons)$true$else$false$endif$") == "true",
  date: [$date$],
)

$body$
