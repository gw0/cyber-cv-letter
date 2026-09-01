# Review cyber1-cv-letter vs cyber2-cv-letter, write improvement plans

## Context

Both `cyber1-cv-letter/` and `cyber2-cv-letter/` are independent Typst
implementations of the same underlying design spec (both cite
`design-cyber.md §4`/`mvp.md` in comments, share the same palette hex
values, spacing philosophy, and accent-rotation logic almost verbatim, and
even the same fictional "Sarah Connor" example persona) — this is clearly
a "two candidate implementations of one spec" comparison. The user wants:
(1) a thorough pros/cons review against Typst best practices, covering
vertical-spacing implementation, file/dir naming, Markdown-workflow
quality, and comment density specifically; (2) a per-implementation
improvement plan saved as `cyber1-improvement.md` and `cyber2-improvement.md`; (3) an
evaluation of which example CV content (both use "Sarah Connor") better
demonstrates the template while being credible for AI/ML, cybersecurity,
and DevOps roles, with concrete improvement ideas; and (4) a clear
recommendation on which implementation is simpler/more maintainable.

Research done: two Explore agents read every `.typ`/`.py`/build/doc file
in both repos. I additionally spot-checked `lib.typ`, `typst.toml`, the
token/theme files, `markup.typ`/`layout.typ` in full, the Makefile vs
README build instructions, the Pandoc bridge templates, both Python
verification scripts, both example `cv.md`/`letter.md` files, and — since
`poppler` wasn't installed — used each repo's own bundled `pymupdf` to
render both example CVs to PNG and visually compared pages 1-2 of each.
Findings below are evidence-backed with file:line references.

## Findings

### Architecture (shared ground)

1,284 (cyber1) vs 1,047 (cyber2) total `.typ` LOC — cyber1 is now the
larger implementation by about a quarter, mainly concentrated in
`markup.typ` (505 lines: the Pandoc content-tree walk, its `show` rules,
and label-measurement helpers). Both support two authoring workflows
(hand-written Typst + Markdown-via-Pandoc) converging on the same
renderer; both enforce a closed section-name vocabulary at compile time;
both wrap decorative marks in `pdf.artifact()` for PDF/UA-1; both verify
ATS text-extraction with two independent Python libraries (pypdf +
pymupdf). The design-token scales have diverged: cyber2's stays purely
em-relative; cyber1's block-level spacing (`tokens.typ`) is now a single
absolute base unit `u = 6.4pt` with every gap a literal multiple of it —
only par leading (`resume.typ`, `letter.typ`) is still `em`-relative in
cyber1.

**Rendering strategy differs, though:** cyber1 is a *hybrid* —
Typst-native `show` rules handle standalone elements (headings, `raw`,
`terms.item`), plus one manual content-tree walk (`render-body`,
`markup.typ:225-321`) just to pair an H2 title with its following meta
line (something show rules can't do — no sibling lookahead). cyber2 does
*full* manual content-tree introspection for the entire document
(`layout.typ:481-540`): it walks H1/H2 boundaries itself and re-emits
fresh `heading()` calls rather than relying on show-rule interception.
cyber2's approach is more internally consistent (one mechanism, not two)
and its own top comment explains a genuine advantage: fresh `heading()`
calls aren't re-matched by any show rule, so heading/outline/PDF-UA-1
tagging "come for free" with no recursion guard needed. cyber1's approach
is more Typst-idiomatic (leans on the built-in show-rule pipeline, which
composes better with anything else a user might add) but asks a reader to
hold two mental models at once.

### Package/build structure

- cyber1: `Makefile` declares the full 8-PDF build matrix as dependency
  rules (`make examples`, `make test`) — reproducible, self-documenting.
  Three independent verification scripts: `scripts/check_contrast.py`
  (WCAG AA), `scripts/check_spacing.py` (asserts every spacing token is a
  literal multiple of `tokens.typ`'s single base unit), and
  `tests/extraction/test_extraction.py` (pytest-discoverable ATS check,
  197L) — though the `Makefile`'s `test` target only runs the last of the
  three; the other two aren't wired into any target. `typst.toml` wires a
  real `[template]` section.
- cyber2: no Makefile; build commands live in the README as copy-paste
  text. Only one verification script, `scripts/ats_check.py` (argparse
  CLI, not pytest-discoverable) — no accessibility-contrast check exists.
  `typst.toml`'s `repository` field is empty; no `exclude` in either
  package's manifest.

### Markdown+Pandoc workflow — cyber2 is the more robust design here

cyber1's Pandoc bridge needs a fragile dual-root workaround: Pandoc
extracts images to an OS-absolute temp path, so the Makefile passes
`--pdf-engine-opt --root=/` (OS root) and threads a `-M root=$(ROOT)`
variable into `src/pandoc/template.typ:15` so the package's *own* imports
resolve through that same anchor (`Makefile:27-39`). It's well-commented,
but it's a global compiler-flag hack: get it wrong and every image or
package import in that build silently breaks. The README's own "seeing
logos/icons in isolation" example command (`README.md:80-91`) has to spell
out five interacting flags by hand.

cyber2 sidesteps the whole problem: the repo registers itself as a local
Typst package (symlinked into
`~/.local/share/typst/packages/local/cyber-cv-letter/0.1.0`), so
`template/cv.typ:21` imports via `@local/cyber-cv-letter:0.1.0` — this
resolves correctly no matter where Pandoc's temp file lives, with **no**
`--root` flag anywhere. This is the more idiomatic, Typst-native fix for
the exact problem cyber1 solves with a workaround, and it's a one-time
environment-setup cost (`README.md:43-51`) rather than a per-invocation
risk. **cyber1 should adopt this pattern.**

### File/directory naming

cyber1: `tokens.typ` / `marks.typ` (decorative drawing) / `markup.typ`
(content-tree walk + show rules) / `resume.typ` (page scaffolding +
header/footer) / `letter.typ`, with Pandoc glue nested under `src/pandoc/`
(named after the tool it serves, tucked away from the public API surface).

cyber2: `theme.typ` / `fonts.typ` / `icons.typ` / `ats.typ` (dedicated
PDF-metadata/artifact module — no cyber1 equivalent, a genuine plus for
discoverability of accessibility-related code) / `layout.typ` (541 lines:
page setup + header rendering + the section/entry parsing state machine +
inline chevron/cursor drawing, all in one file) / `letter.typ`, with
Pandoc glue in a top-level `template/` directory.

Verdict: cyber1's names partition responsibility more precisely — a
reader can guess from the filename alone that decoration lives in
`marks.typ` and CV-specific scaffolding in `resume.typ`. cyber2's
`layout.typ` is a generic name that undersells (and arguably enabled) its
own scope creep into four unrelated concerns. cyber2's top-level
`template/` name is also a latent trap: it sits at repo root next to
`src/`/`examples/`/`fonts/`, inviting confusion with Typst's own
`[template]` package-manifest convention — cyber2's README has to spend a
paragraph clarifying it isn't that (`README.md:143-147`). cyber1 avoids
that ambiguity by nesting Pandoc glue under `src/pandoc/`. cyber2's
`ats.typ` is the one clear naming win in its favor — a dedicated,
discoverable home for accessibility code cyber1 doesn't have.

### Vertical spacing — cyber1 is more consistent and mechanically checked, cyber2 is more granular

cyber1's `tokens.typ` has **9** named spacing constants, all defined as a
literal multiple of one absolute base unit (`u = 6.4pt`, `tokens.typ:87`)
rather than independently-tuned `em` values — a stricter form of the same
"single source of truth per gap weight class" convention documented at
`tokens.typ:52-66`, and one that's now mechanically checked by
`scripts/check_spacing.py` rather than relying on a reader to notice
drift. `space-paragraph` is reused across several visually-similar
call sites (the ambient bare-paragraph gap, the gap around a bullet list,
an entry's meta-block→content gap) by the same deliberate-sharing design.

cyber2's `theme.typ` has **14** named spacing constants, each named after
one specific visual transition (`spacing-title-to-meta`,
`spacing-meta-to-tagline`, `spacing-bullet-to-comment`, etc.) — more
self-documenting at each call site, but with a real, self-acknowledged
duplication problem: **five** separate constants
(`spacing-section-header-to-rule`, `spacing-title-to-meta`,
`spacing-bullet-to-bullet`, `spacing-header-internal`,
`spacing-skills-row-to-row`) all currently equal `0.4em`. `theme.typ:74-82`'s
own comment admits these represent "the same visual role" but keeps them
as five independently-editable names — a real drift risk: changing one
without the others silently breaks the "tight-tier" consistency the
comment describes as intentional.

Visual check (rendered both example CVs to PNG via each repo's bundled
`pymupdf`, since `poppler` wasn't available): both entry meta lines
(org | location) now render in italics for clearer hierarchy against the
body text that follows — no longer a differentiator. cyber2's
terminal-cursor mark after the name still reads as better-proportioned (a
crisp small square at cap-height) versus cyber1's (`marks.typ:29-33`),
which renders slightly heavier/blockier — that gap is unchanged. cyber2
also uses page-1 space more efficiently — its page 1 is filled
almost to the bottom with genuinely more content, while cyber1's page 1
still has roughly 98pt of unused space below its last line of text
(measured via `pymupdf` text-block extraction on `examples/typst/cv.pdf`)
despite thinner content. Both examples still
spill a small tail (Certifications, in both cases) onto an otherwise
near-empty page 2 — both READMEs already document this as a known "no
cross-page keep-together grouping" limitation, so it isn't a
differentiator.

**Recommendation for both plans:** cyber2 should either collapse its five
`0.4em` duplicates into one shared token (if truly meant to move together)
or add a one-line comment on each explaining why it's independent;
cyber1 should keep its consolidation approach as the better long-term
default; its meta-line already renders in italics, matching cyber2's
treatment. Worth double-checking cyber1's cursor-mark proportions (`marks.typ:29-33`,
`h = size * 0.7`, `baseline: h * 0.14`) against cyber2's (`layout.typ:119-124`,
fixed `0.6em × 0.7em`) — cyber2's simpler fixed-em sizing renders more
cleanly here and is one less "eyeballed against ambient size" free variable.

### Comment density

Comment-line / total-line ratio: cyber1 ≈ 42% (480/1142), cyber2 ≈ 24%
(211/870). I read `markup.typ`, `marks.typ`, `tokens.typ`, `theme.typ`,
`layout.typ`, `fonts.typ`, and `icons.typ` in full looking for comments
that just restate what the code already says. **Very few qualify** —
almost every comment in both codebases earns its place by explaining a
non-obvious *why* (a spec citation, an edge case, a rejected alternative,
or — in cyber1's `tokens.typ` — a measured Typst behavior backing a
specific constant). cyber1's ratio is now nearly double cyber2's, driven
mainly by `tokens.typ`'s per-token derivation commentary (145 comment
lines of 252, `tokens.typ:47-159`) and `markup.typ`'s per-fix rationale
comments (233 of 505). The one recurring pattern worth trimming in both:
long derivation/tuning narratives inline with the current values —
`tokens.typ:68-102` in cyber1, `theme.typ:66-82` (17 lines) in cyber2.
These are genuinely useful *design history* but not a *live
constraint* a future reader needs to use or safely modify the token today.
In cyber1's `tokens.typ`, roughly 33 of its 145 comment lines
(`tokens.typ:68-102`, the `u`-derivation and design-spec-ratio-comparison
paragraphs) are this kind of relocatable "tried X, reverted" narrative —
about a quarter of the file's comments; the remainder documents *live*
relationships (which call sites share a token and why, what breaks if they
don't) that a reader modifying the token still needs inline. cyber2's
`theme.typ:66-82` narrative is unchanged — still roughly 5-7% of that
file's comment lines. Outside of that pattern, I found no comments in
either codebase that were purely restating the obvious.

### Example content — cyber2's "Sarah Connor" example is stronger for the target roles

Both use the same fictional persona and company-name in-joke (Cyberdyne
Systems; cyber2 adds Skynet Analytics, Omni Consumer Security) — a
deliberate, thematically-consistent easter egg for a "cyber"-branded
template, not a defect, though it's worth a one-line README note that
it's placeholder content to swap before real use (neither README says
this explicitly today).

Content comparison: cyber2's version (`cyber2-cv-letter/examples/markdown/cv.md`)
is meaningfully better positioned for AI/ML + cybersecurity + DevOps
roles jointly — it shows a clearer career arc (Penetration Tester →
Security Engineer, Applied ML → Senior AI Security Engineer), two
certifications (OSCP + GCIH) vs. cyber1's one (OSCP only), a `PROJECTS`
section demonstrating open-source credibility (400+-star tool), 4 skill
categories vs. cyber1's 3, and explicit DevOps/cloud tooling (Terraform,
AWS, OPA/Gatekeeper, CI/CD security gating, MLflow, Semgrep, Snyk)
alongside classic pentesting tools (Burp Suite, Nmap, Metasploit) and
ML tooling (PyTorch, LLMs) — genuinely covering all three target domains.
cyber1's example stays narrower (mostly AI-security/adversarial-ML, with
Kubernetes/Terraform/Kafka infra but no explicit pentest tooling, no OSS
project, no cloud-security cert), and its rendered page 1 has visibly more
unused whitespace for less content, reinforcing that impression.

**Concrete improvement ideas for the example content (apply to whichever
becomes canonical, or to both):**
1. Add a cloud/security-specific certification (e.g. AWS Certified
   Security – Specialty, or Certified Kubernetes Security Specialist)
   given how much Terraform/AWS/Kubernetes tooling both examples already
   list — currently neither example ties a credential to its heaviest
   infra claims.
2. Exercise more of the template's own section vocabulary in the example
   — neither currently demonstrates `LANGUAGES` or `PUBLICATIONS`, both of
   which are supported and asserted in the closed vocabulary; adding a
   short one would double as a template usage reference.
3. Quantify the open-source project further (weekly downloads, adopting
   org names, or CVE/advisory credit) — cyber2's `promptfirewall` entry
   currently has one metric (GitHub stars); a second, different kind of
   metric would show the range of impact framing the template supports.
4. Add a one-line README note flagging the example as placeholder content
   (fictional company names) to swap before real use.

## Design questions raised (to fold into both plans)

**Closed section-name vocabulary — reconsider coupling name to structure.**
The vocabulary serves two purposes: an ATS-defensibility argument (both
templates' whole premise is judged against a naive ATS extractor, and
standardized headers match what real parsers keyword-match), and, in
cyber2, it's structurally load-bearing — `entry-sections`
(`layout.typ:147`) uses the canonical name to decide whether a section's
H2 children get dated-entry treatment vs. freeform/skills rendering. Both
already leave a one-line escape hatch (extend the vocabulary array
deliberately). A cleaner alternative worth proposing in both plans:
**decouple structure-detection from name-validation** — dispatch rendering
by shape (H2 children with dates → entries; a definition list → skills
row; otherwise → freeform) instead of by name, so an arbitrary section
name ("Awards", "Patents") renders correctly with zero code changes, and
demote the vocabulary check from a hard `panic`/`assert` to a non-fatal
lint/warning nudging toward ATS-conventional names rather than blocking
the build outright.

**The two implementations now disagree on em- vs. absolute-unit spacing —
each has a documented reason.** Both correctly split physical page
geometry (margins, logo cell size, mark gutter) into absolute `pt`/`mm`.
For typographic block-spacing (gaps between text elements), cyber2 keeps
`em`-relative tokens (`theme.typ`), matching CSS's `em`/`rem` convention so
spacing scales proportionally if body size or font changes — with the
sharp edge cyber2's own comments flag: `em` resolves against whatever text
size is *ambient* at the call site, not against the token's own name, so a
spacing call moved into a different `set text` scope can silently change
its rendered size with no error. cyber1 has since moved its block-spacing
tokens (`tokens.typ:87-159`) to a single absolute base unit `u = 6.4pt`
specifically to close that gap — two call sites (`body-indent` in
`resume.typ`'s list, and `markup.typ`'s tech-line pad) must resolve to the
*identical* physical length regardless of local `em` context, which `em`
only guaranteed by coincidence before. cyber1 keeps `em` for one
relationship only — par `leading` (`resume.typ`, `letter.typ`) — since
line-height is conventionally font-size-relative by convention and has
just the one ambient call site. Worth folding into cyber2's plan as an
option, not just a maintenance note: consider whether cyber2's five
duplicate `0.4em` constants (flagged above) would be better served by the
same absolute-unit-grid approach.

## Typst best-practices scorecard

Both follow real best practices: named design tokens, `pdf.artifact()`
for decoration, `sys.inputs` for build-time flag overrides, closed-vocabulary
validation via `panic`/`assert` at compile time, single-entrypoint `lib.typ`
re-exports. Divergence: (1) package resolution — cyber2's local-package
registration is the more idiomatic solution vs. cyber1's `--root`
dual-anchoring workaround; (2) module decomposition and naming — cyber1's
files stay single-purpose even as `markup.typ` has grown to 505 lines,
vs. cyber2's 541-line `layout.typ` mixing four unrelated concerns under a
generic name; (3) spacing-token design — cyber1's fewer (9 vs. 14),
deliberately-shared tokens are now mechanically checked as literal
multiples of one base unit (`scripts/check_spacing.py`), more consistent
by construction than cyber2's more numerous, per-transition tokens, which
are more expressive but currently have unacknowledged-in-practice
duplication.

## Deliverables to produce (after plan approval)

Write two new files at the repo root
(`/home/user/personal/jobs/cyber-comparison/`):

**`cyber1-improvement.md`** — lead with a one-paragraph strengths summary
(Makefile-driven reproducible build, three verification scripts including
the mechanically-checked spacing grid, precise file naming), then
prioritized items:
1. Replace the `--root /` OS-anchoring hack with cyber2's local-package
   registration approach (`@local/...` import) — removes the single most
   fragile piece of the build (`Makefile:27-39`, `src/pandoc/template.typ:9-15`).
2. Add an `exclude` list to `typst.toml` (`.venv`, `examples/*.pdf`,
   `tests`, `__pycache__`).
3. Harden `split-last-pipe()` (`markup.typ:69-87`) with an assertion when
   an org/location line contains more than one `|`.
4. Re-derive/simplify the cursor-mark proportions in `marks.typ:29-33`
   against cyber2's simpler fixed-em version (the meta-line italics gap is
   already closed).
5. Relocate the per-token derivation narrative in `tokens.typ:68-102` (the
   `u`-value and design-spec-ratio-comparison paragraphs) to a
   CHANGELOG/decision log, keeping the live per-token relationship
   rationale inline.
6. Enrich the example CV content per the four ideas above (cert, extra
   section, second OSS metric, placeholder-content note).
7. Wire `check_contrast.py`, `check_spacing.py`, and `test_extraction.py`
   into one `make verify` target.
8. Document the blockquote/`comment-rule` syntax in the README's Content
   model section.
9. Add a regression fixture for `render-body`'s Pandoc
   `parbreak`/`space`-node skipping logic.
10. Consider decoupling entry-vs-freeform rendering from the section-name
    vocabulary (dispatch by content shape instead), demoting the vocabulary
    check to a non-fatal lint — see "Design questions raised" above.

**`cyber2-improvement.md`** — lead with a one-paragraph strengths summary
(idiomatic local-package resolution avoiding the Pandoc root hack,
dedicated `ats.typ`, stronger/more targeted example content), then
prioritized items:
1. Split `src/layout.typ` (541L) into focused, precisely-named modules
   mirroring cyber1's decomposition: e.g. `marks.typ` (chevron/cursor/rule
   drawing, `layout.typ:109-129`), `entries.typ` (the section/entry
   content-tree walk, `layout.typ:481-540`), keeping `layout.typ` itself
   to page/header scaffolding only.
2. Rename the top-level `template/` directory (or clearly re-document it)
   to avoid the naming collision with Typst's own `[template]` package
   convention — e.g. `pandoc/`.
3. Add a Makefile (or equivalent task runner) declaring the build matrix
   as dependency rules, replacing the README's copy-paste command blocks.
4. Add a WCAG AA contrast-check script (port cyber1's `check_contrast.py`)
   — no accessibility contrast verification currently exists.
5. Convert `ats_check.py`'s assertions into pytest-style functions (or add
   a thin pytest wrapper) so it's CI-discoverable like cyber1's test suite.
6. Consolidate or justify the five `0.4em`-valued spacing constants in
   `theme.typ:83-99` (`spacing-section-header-to-rule`,
   `spacing-title-to-meta`, `spacing-bullet-to-bullet`,
   `spacing-header-internal`, `spacing-skills-row-to-row`) — either merge
   into one shared token or document why each must vary independently.
7. Fill in `typst.toml`'s empty `repository` field; add an `exclude` list.
8. Move the "tried X, reverted" tuning narrative in `theme.typ:66-82` to a
   CHANGELOG/decision log.
9. Consider decoupling entry-vs-freeform rendering from the section-name
   vocabulary (dispatch by content shape instead of `entry-sections`
   name-matching, `layout.typ:147`), demoting the vocabulary check to a
   non-fatal lint — see "Design questions raised" above.

## Final recommendation (to state in the response, not just the files)

**cyber1 remains the better foundation for long-term maintainability**,
though the margin is narrower than pure LOC would now suggest — cyber1
has grown to 1,284 total `.typ` lines against cyber2's 1,047, and its
largest file (`markup.typ`, 505 lines) is no longer clearly smaller than
cyber2's flagged 541-line `layout.typ`. What still separates them is
*what* that size is doing: `markup.typ` stays single-concern (the Pandoc
content-tree walk and its `show` rules), while `layout.typ` mixes page
scaffolding, header rendering, entry parsing, and inline drawing in one
file. cyber1's single-purpose file decomposition, Makefile-driven
dependency-tracked build, three verification scripts (including a
spacing scale now mechanically checked rather than eyeballed), reduce the
risk of silent drift as the template grows. Its one real structural wart
— the Pandoc `--root` anchoring hack — is contained, well-documented build
plumbing with a known, better fix: adopt cyber2's local-package-
registration trick (item 1 in `cyber1-improvement.md`).

cyber2's main structural liability — a 541-line `layout.typ` mixing four
different jobs, compounded by a generic filename that invites further
scope creep — is a larger and more central risk than cyber1's Pandoc
wart, since it sits on the hot path every future feature will touch.
cyber2 does have two genuine, worth-adopting wins cyber1 lacks: the
local-package resolution for the Markdown/Pandoc bridge (more idiomatic
and robust than cyber1's workaround), and a dedicated `ats.typ` module
(better discoverability for accessibility code than cyber1's scattered
equivalent). Both plans above are written to cross-pollinate these
strengths in each direction.

On the example content specifically: cyber2's is the stronger starting
point for AI/ML + cybersecurity + DevOps positioning and should be
preferred as the reference example either way, enriched per the four
ideas above.

## Verification

This is a documentation/analysis task with no executable code changes.
After writing both files, read them back to confirm they render as valid
Markdown and accurately reflect the findings above (no code execution
needed).
