// Typst template entry point for a cover letter, consumed by Pandoc's
// "--template" flag on the Markdown-via-Pandoc build path (mvp spec
// section 12). See template/cv.typ for the note on why identity fields
// are passed as bracketed content rather than quoted strings, and why no
// literal "dollar-name-dollar" token may appear in this file outside the
// substitution block below (Pandoc replaces those everywhere, comments
// included).
#import "@local/hacker-cv:0.1.0": cover-letter

#show: cover-letter.with(
  name: [$name$],
  tagline: [$tagline$],
  email: [$email$],
  phone: [$phone$],
  location: [$location$],
  links: ($for(links)$"$links$",$endfor$),
  date: "$date$",
  paper: "$paper$",
  font-chrome: "$font-chrome$",
  font-body: "$font-body$",
)

$body$
