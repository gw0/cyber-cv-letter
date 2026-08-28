// Thin pandoc --template target for the CV. Populates #show: cv-resume.with(...)
// from YAML front matter / -V variables, then passes the converted body
// through untouched — the same markup.typ show rules that fire for a
// hand-written direct-Typst document fire here too (spec/20260828-mvp.md
// §11.1). Note for future edits: pandoc's template scanner scans this
// entire file's raw text for its own placeholder syntax, including inside
// Typst comments, so a dollar-sign-delimited word in prose here would get
// substituted too — describing the syntax in words, not by example.
// root is supplied by the Makefile as the repository's absolute filesystem
// path, via -M. Typst treats a leading slash as project-root-relative,
// never as a true OS-absolute path, so with --pdf-engine-opt --root / set
// to the OS root (required for the media images Pandoc extracts to
// resolve at all — see Makefile comment) this package's own sources must
// be reached the same way, through that same OS-root anchor.
#import "$root$/src/resume.typ": cv-resume

#show: cv-resume.with(
  author: (
    name: "$name$",
$if(tagline)$    tagline: "$tagline$",
$endif$$if(email)$    email: "$email$",
$endif$$if(location)$    location: "$location$",
$endif$$if(phone)$    phone: "$phone$",
$endif$$if(links)$    links: ($for(links)$"$links$",$endfor$),
$endif$  ),
$if(accent)$  accent: "$accent$",
$endif$$if(accent-scope)$  accent-scope: "$accent-scope$",
$endif$$if(variant)$  variant: "$variant$",
$endif$$if(paper-size)$  paper-size: "$paper-size$",
$endif$$if(font)$  font: "$font$",
$endif$$if(header-font)$  header-font: "$header-font$",
$endif$$if(show-logos)$  show-logos: true,
$endif$$if(show-icons)$  show-icons: true,
$endif$$if(show-footer)$  show-footer: true,
$endif$)

$body$
