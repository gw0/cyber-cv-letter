// Thin pandoc --template target for the cover letter — sibling of
// template.typ, wired to cv-letter() instead of cv-resume() since a
// letter's setup parameters differ (date, no show-logos/show-icons; §11.4).
// See template.typ for why this is an OS-root-anchored path.
#import "$root$/src/letter.typ": cv-letter

#show: cv-letter.with(
  author: (
    name: "$name$",
$if(tagline)$    tagline: "$tagline$",
$endif$$if(email)$    email: "$email$",
$endif$$if(location)$    location: "$location$",
$endif$$if(phone)$    phone: "$phone$",
$endif$$if(links)$    links: ($for(links)$"$links$",$endfor$),
$endif$  ),
  date: "$date$",
$if(accent)$  accent: "$accent$",
$endif$$if(accent-scope)$  accent-scope: "$accent-scope$",
$endif$$if(variant)$  variant: "$variant$",
$endif$$if(paper-size)$  paper-size: "$paper-size$",
$endif$$if(font)$  font: "$font$",
$endif$$if(header-font)$  header-font: "$header-font$",
$endif$$if(show-footer)$  show-footer: true,
$endif$)

$body$
