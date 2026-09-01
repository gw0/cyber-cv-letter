# Improvement plan — cyber2-cv-letter

## Where this implementation stands

cyber2 gets two things right that its sibling (cyber1) doesn't: it
resolves the Markdown+Pandoc bridge via a proper local Typst package
registration (`@local/cyber-cv-letter:0.1.0`) instead of a fragile
`--root` OS-anchoring hack, and it has a dedicated `src/ats.typ` module
giving accessibility/PDF-metadata code a discoverable home. Its example
CV content ("Sarah Connor") is also the stronger of the two for AI/ML +
cybersecurity + DevOps positioning — broader career arc, two
certifications, a `PROJECTS` section, and tooling spanning all three
target domains. Its main liability is architectural concentration: most
of the rendering logic lives in one 541-line file. The improvements below
address that concentration and close a few build/tooling gaps, without
touching what already works well.

## Prioritized improvements

1. **Split `src/layout.typ` (541 lines) into focused, precisely-named
   modules.** Today it mixes page/header scaffolding, decorative drawing,
   and the full section/entry content-tree-parsing state machine in one
   file — the file most likely to become a bottleneck as the template
   grows, and a generic name (`layout.typ`) that doesn't hint at that
   scope. Mirror the sibling implementation's decomposition:
   - `marks.typ` — `draw-chevron`, `draw-cursor`, `draw-rule`
     (`layout.typ:109-129`).
   - `entries.typ` (or `parse.typ`) — the section/entry content-tree walk:
     `flatten-text`, `split-last`, `split-paragraphs`, `validate-section`,
     `render-entry`, `render-bullets`, `render-skills-row`
     (`layout.typ:19-377`).
   - Keep `layout.typ` itself to page setup, `render-header`, and the
     top-level `cv()` orchestration that calls into the split-out modules
     (`layout.typ:383-541`).

2. **Rename (or clearly re-document) the top-level `template/`
   directory.** It sits at repo root next to `src/`/`examples/`/`fonts/`
   and holds Pandoc `--template` glue (`template/cv.typ`,
   `template/letter.typ`) — but the name collides conceptually with
   Typst's own `[template]` package-manifest convention (the thing
   `typst init` scaffolds from). The README already has to spend a
   paragraph clarifying this isn't that (`README.md:143-147`); renaming to
   something like `pandoc/` (matching the sibling implementation's
   `src/pandoc/` naming) removes the ambiguity at the source instead of
   documenting around it.

3. **Add a Makefile (or equivalent task runner).** Build commands
   currently live in the README as copy-paste text (`README.md:59-88`) —
   correct today, but nothing catches drift if a documented command
   stops matching the flags the code actually expects. A declarative
   build matrix (`make examples`, `make test`) removes that risk and
   matches the sibling implementation's approach.

4. **Add a WCAG AA contrast-check script.** No accessibility-contrast
   verification exists in this implementation — only ATS-extraction
   checking (`scripts/ats_check.py`). Port the sibling's
   `scripts/check_contrast.py` (computes contrast ratios against the
   4.5:1 AA floor for every palette color in `theme.typ`) so color-token
   edits get the same automated safety net extraction already has.

5. **Make `ats_check.py` CI-discoverable.** It's currently an argparse
   CLI script rather than pytest-style test functions
   (`scripts/ats_check.py`), which adds friction to wiring it into a
   standard CI test runner. Add a thin pytest wrapper (or convert its
   assertions directly) so `pytest` alone finds and runs it, matching the
   sibling implementation's `tests/extraction/test_extraction.py`.

6. **Consolidate or justify the five `0.4em`-valued spacing constants.**
   `src/theme.typ:83-99` defines `spacing-section-header-to-rule`,
   `spacing-title-to-meta`, `spacing-bullet-to-bullet`,
   `spacing-header-internal`, and `spacing-skills-row-to-row` as five
   independent names that all currently equal `0.4em` — the file's own
   comment (`theme.typ:74-82`) already acknowledges these represent "the
   same visual role." Keeping them independent risks silent drift: editing
   one without the others quietly breaks the "tight-tier" consistency the
   comment describes as intentional. Either merge them into one shared
   token, or add a one-line comment on each explaining why it must be
   free to vary independently in the future.

7. **Fill in package manifest gaps.** `typst.toml`'s `repository` field
   is empty (`typst.toml:8`) — add the actual repo URL. No `exclude` list
   exists either; add one (`fonts/*.ttf` is arguably fine to ship, but
   `examples/*.pdf`, `__pycache__`, and any local venv should be excluded
   if this is ever published).

8. **Relocate the long tuning narrative out of `theme.typ`.**
   `src/theme.typ:66-82` (17 lines) documents a "starting values adapted
   from ..., then visually tuned" history. Useful design history, not a
   live constraint — move it to a CHANGELOG/decision log, keeping only
   the current rationale inline.

9. **Consider decoupling entry-rendering from the section-name
   vocabulary.** `entry-sections` (`layout.typ:147`) uses the *canonical
   name* to decide whether a section's H2 children get dated-entry
   treatment or freeform rendering — here the vocabulary is genuinely
   load-bearing for rendering shape, not just an ATS-naming nudge. Worth
   considering a shape-based dispatch instead (H2 children with dates →
   entries; a definition list → skills row; otherwise → freeform),
   letting an arbitrary section name ("Awards", "Patents") render
   correctly with zero code changes, and demoting `validate-section`'s
   `panic` (`layout.typ:149-163`) to a non-fatal lint nudging toward
   ATS-conventional names rather than blocking the build outright.
