// Font-chrome / font-body resolution (mvp spec §8).
//
// `font-chrome` and `font-body` are independent family-name strings. Typst's
// own font resolution already does the right thing: the compiler is invoked
// with the repo's `fonts/` directory on its font search path (see the build
// scripts), so a name matching a bundled family (`"IBM Plex Mono"`,
// `"IBM Plex Sans"`, `"Roboto"`, `"Source Sans Pro"`) resolves to the bundled
// files; any other name falls through to a system-installed font of that
// name. No per-family branching is needed here — the name is passed through
// verbatim.

#let default-font-chrome = "IBM Plex Mono"
#let default-font-body = "IBM Plex Sans"
