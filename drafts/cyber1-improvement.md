# Improvement plan — cyber1-cv-letter

## Where this implementation stands

cyber1 is the stronger foundation of the two sibling implementations for
long-term maintainability: a Makefile declares the full 8-PDF build matrix
as reproducible dependency rules (`Makefile`), three independent
verification scripts cover accessibility (`scripts/check_contrast.py`,
WCAG AA), spacing-scale integrity (`scripts/check_spacing.py`, asserting
every spacing/indent token is a literal `N * u` multiple of one base unit),
and ATS-extraction (`tests/extraction/test_extraction.py`,
pytest-discoverable), and the source is split into small, precisely-named,
single-purpose files (`tokens.typ`, `marks.typ`, `markup.typ`,
`resume.typ`, `letter.typ`). Its spacing scale is deliberately DRY and now
mechanically enforced rather than eyeballed: `tokens.typ:87-159` derives
every one of 9 named tokens as a literal multiple of a single base unit
`u = 6.4pt`, checked by `check_spacing.py`, and reused across
visually-similar gaps rather than one-token-per-call-site. `markup.typ`
(505 lines) is now the one file worth watching — still single-purpose
(the Pandoc content-tree walk plus its `show` rules, no page scaffolding
mixed in, unlike the sibling implementation's largest file), but its size
is no longer the clear advantage it once was. The improvements below are
refinements to a solid base, not a rewrite.

## Prioritized improvements

1. **Replace the `--root /` Pandoc-anchoring hack with local-package
   registration.** `Makefile:27-39` sets `--pdf-engine-opt --root=/` (OS
   root) and threads a `-M root=$(ROOT)` variable into
   `src/pandoc/template.typ:9-15` so the package's own imports resolve
   through the same anchor Pandoc needs for its extracted images. This is
   a global compiler-flag hack — get it wrong and every image or package
   import in that build silently breaks (the README's own
   logos/icons-in-isolation example, `README.md:80-91`, already has to
   spell out five interacting flags by hand). The sibling implementation
   (cyber2) solves the identical problem by registering the repo as a
   local Typst package (symlinked into
   `~/.local/share/typst/packages/local/...`) and importing via
   `@local/cyber-cv-letter:0.1.0` — this resolves correctly regardless of
   where Pandoc's temp file lives, with no `--root` flag anywhere, and the
   cost is a one-time environment-setup step rather than a per-invocation
   risk. Adopt that pattern here; it removes the single most fragile piece
   of the build.

2. **Add an `exclude` list to `typst.toml`.** No `exclude` field exists
   today, so `.venv/`, checked-in example PDFs, font/test fixtures would
   all ship if this were ever published as a package:
   ```toml
   exclude = [".venv", "examples/*.pdf", "tests", "__pycache__", "*.pyc"]
   ```

3. **Harden `split-last-pipe()` against multiple `|` characters.**
   `src/markup.typ:69-87` splits an org/location line on the *last* `|`;
   the README documents "a title containing `|` is theoretically
   possible" as a known edge case but the code doesn't guard it — an org
   name like `Foo | Bar | Location` silently mis-parses as org=`Foo | Bar`
   without any warning. Add an assertion (or at minimum a build-time
   warning) when more than one `|` is present, pointing the author at the
   ambiguity rather than silently guessing.

4. **Reconsider cursor-mark proportions against the sibling
   implementation.** `entry-meta-parts`'s org/location line already
   renders in italics (`src/markup.typ:150`), matching the sibling
   implementation's meta-line treatment. What's left: cyber1's cursor mark
   (`src/marks.typ:29-33`, `h = size * 0.7`, `baseline: h * 0.14`) reads
   slightly heavier/blockier than the sibling's simpler fixed-em version
   (`0.6em × 0.7em`, no ambient-size dependency) — worth comparing
   side-by-side and simplifying if the fixed-em version looks cleaner.

5. **Relocate the derivation narrative out of `tokens.typ`.**
   `src/tokens.typ:47-159` carries substantial inline commentary
   justifying each token — why `u = 6.4pt` (the smallest value at which
   `space-bullet` still clears the fixed 0.6em wrapped-line leading), why
   each multiplier was chosen by rendering and comparing against
   previously-approved output rather than the design spec's own literal
   ratio table, and why several relationships (e.g. `space-paragraph`,
   `space-header-line`) are deliberately shared across multiple call
   sites. This is a real improvement over "tried X, reverted" folklore —
   it's mechanism-grounded and each claim is checkable — but it's also
   longer than before and still lives inline with the values it justifies.
   Keep the one-line rationale for *why* each token is a literal multiple
   of `u` next to the token (that's what a future reader modifying a
   single value needs), and move the longer per-token derivation stories
   (the specific pt values tried, the measurement process, the comparison
   against prior PDFs) to a CHANGELOG or decision log.

6. **Enrich the example CV content.** The sibling example (cyber2's
   "Sarah Connor") remains more credible for AI/ML + cybersecurity +
   DevOps roles jointly — broader career arc, two certifications vs. one,
   a `PROJECTS` section, and explicit DevOps/cloud tooling alongside
   pentesting and ML tooling. Either adopt that content directly or
   enrich `examples/markdown/cv.md` / `examples/typst/cv.typ` similarly:
   - Add a cloud/security-specific certification (e.g. AWS Certified
     Security – Specialty, or CKS) to back up the Kubernetes/Terraform
     claims already in the example.
   - Add a `PROJECTS` or `LANGUAGES` section to exercise more of the
     supported closed vocabulary as a usage reference.
   - Quantify the fuzzer/tooling callouts with a second, different kind of
     metric (adoption, CVE credit, downloads) alongside the ones already
     present, to show a wider range of impact framing.
   - Add a one-line README note flagging the example as placeholder
     content (fictional company names) to swap before real use.

7. **Wire the verification scripts into one Makefile target.** Three
   independent scripts now exist — `scripts/check_contrast.py`,
   `scripts/check_spacing.py`, `tests/extraction/test_extraction.py` — and
   the `Makefile`'s only test-related target (`test`, `Makefile:92-93`)
   runs just `test_extraction.py`. A `make verify` (or folding the other
   two into `test`) running all three together would make "did I break
   anything" a single command instead of three to remember.

8. **Document the blockquote/`comment-rule` syntax in the README's Content
   model.** `src/markup.typ:419-457`'s `comment-rule` (wired via
   `show quote: markup.comment-rule(font)` in `src/resume.typ`) renders a
   Markdown blockquote immediately following a bullet as a muted,
   expanded-detail annotation — but `README.md`'s "Content model" section
   (`README.md:32-56`) only documents section headings, entries, skills,
   and tech-lines. A user reading the README alone has no way to discover
   this syntax exists. Add a bullet describing it alongside the other
   content-model rules, including the "must immediately follow a bullet"
   positional constraint that the entry-pairing rule already models.

9. **Pin down the Pandoc node-skipping logic with a regression fixture.**
    `render-body` (`src/markup.typ:225-321`) skips stray `parbreak` and
    `space` content nodes that Pandoc's Typst writer emits around headings,
    to keep the zero-gap-after-a-section-rule logic correct. The comments
    there note this shape was reverse-engineered by dumping `k.func()`
    against this document's actual Pandoc output — it isn't derived from
    any documented Pandoc/Typst-writer contract. Nothing in
    `tests/extraction/test_extraction.py` (text-extraction only) or
    `scripts/check_spacing.py` (token values only) would catch a future
    Pandoc version emitting a different node shape here; only a visual diff
    would. Worth a small fixture test that runs the Markdown workflow
    through `render-body` and asserts on the resulting content tree (or at
    minimum a documented manual-check step) so a future Pandoc upgrade
    doesn't silently reopen the gap this code fixes.

10. **Consider decoupling entry-rendering from the section-name
    vocabulary.** The closed vocabulary (`section-vocabulary`,
    `src/markup.typ:93-102`) is validated at compile time via `assert`
    and exists primarily for ATS-defensibility (standardized headers
    match what real resume parsers keyword-match against) — it's a
    deliberate, documented product decision, not an accident, and it
    already leaves an escape hatch (extend the array deliberately).
    Still, worth considering: dispatch *rendering* by content shape (H2
    children with dates → entries; a definition list → skills row;
    otherwise → freeform) rather than relying on Typst's structural
    handling being section-name-agnostic already for entries (it is, in
    cyber1 — any H2 is treated as an entry regardless of enclosing
    section). If the vocabulary check is purely an ATS-naming nudge and
    not load-bearing for rendering shape here, consider demoting it from
    a hard `assert` to a non-fatal warning, so a user who deliberately
    wants a custom section name (e.g. "Awards") isn't blocked outright.
