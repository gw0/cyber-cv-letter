# Design Guidelines — Hacker/Terminal Personal Brand

## 1. Scope, audiences, non-goals

### 1.1 What this document is

A design specification: palette, typography, layout, motif vocabulary, and the output
contract for the PDF. It is detailed enough that an implementer can build the templates
without asking follow-up questions.

### 1.2 Audiences and their failure modes

The CV is read by three parties, and each fails differently. The design must satisfy all
three, in this order:

| Audience | Time budget | Failure mode | What it needs |
|---|---|---|---|
| **ATS parser** | milliseconds | Silently ranks you near zero. You never hear about it. | Linear single-column text, standard section keywords, real text (not images), consistent dates |
| **Recruiter** | ~7–30 s first pass | Skims past you. | Strong job titles, clear section landmarks, whitespace, quantified outcomes above the page-one midpoint |
| **Engineer / hiring manager** | 1–3 min | Reads it, isn't convinced. | Specific technical detail, decisions and trade-offs, credible metrics |

The parser is the gate, so it wins every conflict. The recruiter is the filter, so
scannability wins the next tier. The engineer is the decision, so detail must survive
into page two rather than being compressed away.

### 1.3 Non-goals

- Content and copywriting guidance (what to claim, how to phrase achievements). Separate concern.
- Full website implementation spec — §10 gives the token bridge only.
- **The theme implies no security capability.** Terminal, cryptography, and AI/ML motifs
  are aesthetic branding for a software engineering candidate. Nothing in this design
  should be read as a claim about offensive security work.

---

## 2. Design principles

### 2.1 The precedence ladder

When two rules conflict, the earlier one wins. No exceptions, no case-by-case debate.

```
parseable  >  legible  >  scannable  >  characterful
```

The aesthetic is a **tie-breaker**, never a constraint. If a motif costs parseability or
legibility, the motif goes. This is the entire reason the design works: it never asks the
reader to trade comprehension for personality.

### 2.2 Two lanes

Every element on the CV belongs to exactly one lane, and the lane is decided at design
time, not per-element by taste.

**ATS lane — real content.** Name, contact details, section keywords, job titles,
employers, locations, dates, bullets, skills. Plain text. Standard vocabulary. Linear
top-to-bottom order. Nothing decorative is allowed to touch it.

**Human lane — decoration.** Marks, rules, accent colour. The governing rule is:

> **Decoration is drawn, not typed.**

Every human-lane element is a vector path — `line`, `curve`, `rect` — wrapped in
`pdf.artifact`. It contributes **zero characters** to the text stream, so no extractor can
merge it into content, at any position, under any circumstance.

Where decoration genuinely must be a string, it falls back to a second rule: **never on
the same text baseline as ATS-lane text.** There are exactly two such cases — the CV
footer and the cover letter's footer (§6.8, Appendix A) — because a shell prompt is a
string and drawing one would be absurd. Both are the same shape: they sit alone on their
lines, in a footer zone parsers are documented to skip entirely.

### 2.3 Why drawn, not typed — worked example

The obvious way to render a terminal-flavoured section header:

```
jane@ena:~$ cat experience.md
```

Extracts as exactly that string. A parser segmenting sections by matching a line against
`^\s*(work\s+)?experience\s*$` does not match, the section is never identified, and every
job inside it is orphaned. The visual joke costs the entire employment history.

Moving the sigil into a left margin gutter does **not** fix it. A `$` at x=15 mm and
`EXPERIENCE` at x=24 mm on the same baseline still extracts as `$ EXPERIENCE` — one line,
still no match. Extractors break lines on *y*-position; horizontal distance is invisible
to them. A gutter looks safe and isn't.

Exiling the sigil to the rule line below the header does work, but only by giving up the
placement that looks best, and it leaves a stray `$` in the extracted text forever.

**Drawing the mark removes the problem rather than working around it.** A chevron built
from two 0.6pt strokes, one monospace cell wide, sitting on the header baseline:

```
❯  EXPERIENCE          ← the ❯ here is a drawn path, not a character
   ───────────────────────────────────────
```

Extraction yields:

```
EXPERIENCE
```

That is the whole output. Nothing to isolate, nothing to explain, nothing that can drift
back onto the keyword's line during a future layout change. The mark can now sit wherever
it looks best, because position no longer carries risk.

Two further gains: the mark's stroke weight is set to match the rules exactly, so
decoration reads as one line system rather than a character parked beside a line; and it
no longer depends on IBM Plex Mono being present (§2.4).

### 2.4 Motifs must degrade

Every design decision has to survive three degradations, because all three happen in
practice:

- **Greyscale print.** Colour may carry emphasis, never information. Removing all colour
  must leave the document fully intelligible and correctly ranked by visual hierarchy.
- **Font substitution.** If IBM Plex is unavailable and a fallback is used, the layout
  may shift but must not break. No design element may depend on exact glyph widths.
- **Plain-text extraction.** The `txt` build (§9) is not a fallback, it is a first-class
  output. If the design only works with its ornament, the design is wrong.

### 2.5 The author cannot break it

Motifs are injected by show rules in the Typst template, never written by hand in the
Markdown source. The source stays ordinary Markdown following the contract in §9.2 —
`## Experience`, not `## $ cat experience.md`. This makes the ATS lane correct **by
construction**: content and decoration live in different files, so no way of writing
content can violate §2.2. The template additionally fails the build on a section heading
outside the §7.2 vocabulary, which closes the one remaining gap.

---

## 3. Motif vocabulary — one grammar, three dialects

### 3.1 The problem, and the resolution

Hacker + cryptography + AI/ML is three themes at once. Three themes competing for the
same surface is the standard way a personal identity turns to mush — each one dilutes the
others and the result reads as "likes computers" rather than as a specific person.

**Resolution: the terminal/CLI is the only visual grammar.** Cryptography and AI/ML never
become competing visual systems. They appear as *content inside the terminal*. A key
fingerprint is something the shell printed. A training log is something the shell is
streaming. One container, three kinds of payload. This gives thematic range without
visual incoherence, and it means the whole identity is describable in one sentence.

### 3.2 Tiering by surface

Loudest to quietest. Volume drops as the stakes rise.

| Surface | Terminal | Cryptography | AI/ML |
|---|---|---|---|
| **Homepage / blog** | prompt, blinking cursor, boxed panels, `ls`-style listings | `ssh-keygen` randomart block, PGP fingerprint in footer, hash-prefixed permalinks | streaming-token reveal on hero text, attention-grid favicon, embedding-scatter section dividers, training-log-styled footer |
| **Cover letter** | footer prompt line (identical to CV's, optional), drawn chevron beside the date | — | — |
| **CV** | drawn chevron + block cursor, drawn rules | — | vocabulary only (§3.3) |

### 3.3 AI/ML on the CV: vocabulary, not ornament

The AI/ML signal on the CV comes from **how things are written**, not from graphics:

- Tensor-shaped notation where it is genuinely informative:
  `Cut attention memory 4× by rewriting the [batch, heads, seq, seq] path.`
- A skills taxonomy that groups the way practitioners group:
  `Training · Inference · Data · Serving` rather than `Languages · Tools · Other`.
- Metrics stated in the field's own units: tokens/s, p99 latency, MFU, eval deltas with
  the benchmark named.

This reads as fluency to anyone in the field and extracts as ordinary text.

**Banned on the CV, without exception:**

| Banned | Why |
|---|---|
| Proficiency bars, star ratings, percentage rings | A graphic where a parser expects text; also poorly regarded by human reviewers, who read them as unverifiable self-assessment |
| Radar / spider charts | Same, plus unreadable in greyscale |
| Attention-matrix or heatmap skill grids | A table in disguise — the single worst structure for ATS parsing |
| Loss-curve sparklines | Decorative image conveying nothing checkable |
| viridis / plasma / magma gradients | Clashes with the palette, and encodes information in colour (violates §2.4) |

### 3.4 Colour ramps

If the site needs a sequential ramp (tag heat, activity calendar, chart series), derive it
from Gruvbox tones rather than importing a scientific-visualisation palette:

```
dark theme  (bright set)   #b8bb26 → #fabd2f → #fe8019 → #fb4934
light theme (faded set)    #79740e → #b57614 → #af3a03 → #9d0006
```

Match the set to the background per §4.2. `#b57614` is 3.77:1 on white, so the light ramp
is for fills and large marks, not small labels. Never on the CV or cover letter.

### 3.5 Glyph inventory

**Decoration is drawn, never typed** (§2.2), so it has no glyph inventory — see §4.5 for
the two marks and their geometry. The exceptions are the two footer prompts — the CV's
(§6.8) and the cover letter's (Appendix A) — which are genuine strings, sitting alone in a
zone parsers skip. Box-drawing characters (`─ │ ├ └ ═`) are **web-only**: on the CV they
would extract as character runs.

**Allowed inline, in content:**

```
•   -   ·   →   –   /   |
```

`•` and `-` are the only bullet markers parsers reliably recognise. `·` and `|` are
delimiters for skills and contact lines. `→` is permitted inside bullet prose
(`340 ms → 90 ms`) because it carries meaning and extracts as U+2192.

**Banned inline:**

```
★   ■   ➤   ✓   ❯   ◆   ➔   ⚡   any emoji
```

Exotic bullet glyphs are known to be dropped or to break list parsing, and several map
into font-specific ranges that do not round-trip through text extraction.

---

## 4. Design tokens

Gruvbox, expressed as semantic names. Implementations reference the token, never the hex.

### 4.1 Palette

All tokens are shared across both accent presets except `accent` itself, which is a
build-time choice (§9.3) — not a fixed value. `bg`, `fg`, `muted`, `secondary` never
change when the preset changes.

| Token | Print / light | Web dark | Contrast on white | Verdict | Use |
|---|---|---|---|---|---|
| `bg` | `#ffffff` | `#282828` | — | — | page background |
| `fg` | `#3c3836` (bg1) | `#ebdbb2` (fg1) | **11.6 : 1** | AAA | body text |
| `muted` | `#7c6f64` (light gray) | `#a89984` (fg4) † | **4.87 : 1** | AA | dates, locations, meta |
| `secondary` | `#076678` (faded blue) | `#83a598` (bright blue) | **6.60 : 1** | AA at any size | links, secondary tags |
| `surface` | `#fbf1c7` (bg0) | `#32302f` (bg0_s) | — | — | tinted panels, code blocks — **web only** |

**`accent` — selectable preset.** Chosen with `-V accent=` at build time (§9.3). Both
presets are fully specified and pre-verified; picking one is a one-flag build, not a
retune.

| Preset | Print accent | Contrast on white | Dark web accent | Contrast on `#282828` | Use |
|---|---|---|---|---|---|
| `red` (original, renamed from `orange` — it reads red, not orange, in practice) | `#af3a03` (faded orange) | **6.12 : 1** AA any size | `#fe8019` (bright orange) | **5.84 : 1** AA any size | name, section headers, rules |
| `green` (new, default) | `#157d00` (custom, true-green hue, brighter revision) | **5.29 : 1** AA any size | `#b8bb26` (bright green) | **7.14 : 1** AA any size | name, section headers, rules |

Dark-theme values for the shared tokens are measured against `#282828`: `fg` 10.75:1,
`secondary` 5.48:1, `muted` 5.30:1. All clear AA.

† **Not Gruvbox's `gray #928374`.** The canonical dark-theme gray measures **4.02:1** on
`#282828` and fails AA for normal text — a genuine defect in the stock palette that most
Gruvbox ports inherit, because terminal themes are not contrast-audited for small UI text.
`fg4 #a89984` is one step lighter, still unmistakably the muted tone, and clears AA at
5.30:1. Use `#928374` for decorative strokes only, never for text.

### 4.2 Why these values, per accent preset

**Gruvbox is a dark palette. Its light variant is tuned for cream `#fbf1c7`, not white.**
This matters more than it sounds. Gruvbox ships three accent sets — *bright* (for dark
backgrounds), *neutral*, and *faded* (for light backgrounds). The neutral set is the one
people reach for when building a light theme, and on pure white it is wrong:

| Gruvbox set | Orange | On white | Verdict |
|---|---|---|---|
| bright | `#fe8019` | 2.5 : 1 | ❌ fails badly — dark-background value |
| neutral | `#d65d0e` | 3.87 : 1 | ❌ fails AA for normal text; legal only ≥14pt |
| **faded** | **`#af3a03`** | **6.12 : 1** | ✅ AA at any size |

The print palette therefore uses the **faded** set throughout for the `red` preset.
This is not a departure from Gruvbox — it is the part of Gruvbox actually designed for
light backgrounds.

**The `green` preset needed the same treatment.** The same check was run for every stock
Gruvbox green, plus the signature green of Everforest (a Gruvbox-adjacent terminal
palette), before concluding that none of them clear AA on white with real headroom:

| Candidate | On white | Verdict |
|---|---|---|
| Gruvbox bright `#b8bb26` | 2.06 : 1 | ❌ fails badly — dark-background value |
| Gruvbox neutral `#98971a` | 3.10 : 1 | ❌ fails AA for normal text |
| Gruvbox faded `#79740e` | 4.86 : 1 | ⚠️ bare AA minimum — same margin as this doc's `muted` floor, and muddy on white (see below) |
| Everforest signature `#8DA101` | 2.90 : 1 on white; **2.81 : 1 on its own native `bg0 #FFFBEF`** | ❌ fails AA even in its home theme — it is a UI-accent/syntax colour, not body-contrast-rated |

No established terminal-green scheme clears AA on a light background with headroom — this
is exactly the gap §4.2 already found for red.

**Darkening Gruvbox's own hue is not enough — the hue itself is the problem.** A first
pass just retuned the tone at Gruvbox's existing green hue (~74°, yellow-green — the same
hue family as `#79740e`), the same fix used for red. That value cleared AA fine, but
review confirmed it still read as muddy olive rather than terminal green, because the
muddiness in that whole hue family comes from the yellow shift, not from lightness — no
amount of further darkening removes it, it only makes an olive that is also darker.

The fix is a hue shift, not just a tone retune: move off Gruvbox's yellow-green entirely
and onto a true-green hue (~110–120° in HSL, full saturation), verified computationally
across a hue-by-contrast grid rather than picked by eye. That scan also surfaces a hard
ceiling worth stating plainly: **at full saturation, the brightest possible AA-passing
(4.5:1) green on white is `#008b00`** — no hue or saturation choice gets meaningfully
brighter while staying legible, because green carries the largest weight (0.7152) in the
WCAG relative-luminance formula. A saturated "neon terminal green" like `#33cc00` (2.15:1
on white) is a dark-background value for exactly this reason, the same failure mode as
Gruvbox's own bright green (2.06:1, table above).

The chosen value, `#157d00` (hue ≈110°, full saturation, a brighter shade of the same
true-green hue as an earlier, darker candidate at this hue) lands at **5.29 : 1** on
white — clear of the 4.5:1 AA-any-size floor, though with less headroom than the red
preset's 6.12:1 — while reading as true green rather than olive, because the hue sits
well clear of the 57–74° range where the muddiness lives. The dark-web side needs no
retuning: stock Gruvbox bright green `#b8bb26` is already built for dark backgrounds and
clears **7.14 : 1** on `#282828`.

**One accent, not two — per preset.** An earlier draft carried both `#d65d0e` (rules,
large headers) and `#af3a03` (small text), because the neutral orange is prettier. That
split is a permanent footgun: every implementer has to remember which orange is legal
where, and the failure mode is silent — a date set in the wrong orange looks fine on
screen and fails accessibility in print. Collapsing to the single faded orange costs a
little vibrancy and removes the whole class of error. **`accent` is legal at any size** —
and this holds independently within each preset: whichever preset is selected, there is
exactly one `accent` value for that preset, not a size-dependent split.

**Olive needed a hue shift, not avoidance.** `#79740e` clears AA on white at a bare
4.86:1, but a desaturated yellow-green on pure white reads muddy — it was tuned to sit on
cream, where the shared warmth makes it work, and darkening it further (§4.2 above) only
produces a darker olive, not a cleaner green. That is not a reason to avoid green as a
preset; it means the green preset can't be derived from Gruvbox's own green hue at all —
`#157d00` moves to a true-green hue outside Gruvbox's palette entirely, custom-built for
white the same way `#af3a03` is custom-selected from Gruvbox's *faded* set for the red
preset.
Links use faded blue `#076678` in both presets: cleaner on white, 6.60:1, still Gruvbox,
and shared so the two presets stay visually coherent with each other.

**Cream is demoted to `surface`, web only.** Setting the CV on a cream background would
put the palette back in its native habitat, and it is the wrong call: a full-bleed tint is
ink-heavy, prints oddly on white stock, disappears entirely when a reviewer prints
backgrounds off, and reads as a design-tool export. White paper is the base for both the
PDF and the web light theme, so there is exactly **one** light background to verify
against. Cream survives as a tint for code blocks and panels on the site.

### 4.3 Greyscale rule

Colour carries emphasis only. Print the document greyscale and nothing informational may
be lost. Concretely: a section header is identifiable by its size, weight, capitalisation,
and rule — the accent colour is the fourth redundant signal, not the first.

Greyscale luminance ordering, which the palette was checked against — and which must hold
for **whichever accent preset is active**:

```
red preset:     fg 0.041   <   secondary 0.109   <   accent 0.122   <   muted 0.166
green preset:   fg 0.041   <   secondary 0.109   <   accent 0.148   <   muted 0.166
                 darkest                                                   lightest
```

Same ordering holds for both presets, though the accent luminance no longer nearly
matches between them now that the green hex has been revised brighter — red `0.1215`
(tuned to 6.12:1) vs green `0.148` (tuned to a brighter 5.29:1). The green preset's
margin to `muted` is correspondingly tighter than red's (0.018 vs 0.044) — still on the
right side of the ordering, but worth watching if the green value is ever retuned again.

Two consequences worth stating rather than discovering later. **`accent` prints darker
than `muted`, in both presets**, so section headers stay visually heavier than dates when
colour is removed — that ordering is deliberate and must be preserved if either preset's
value is ever retuned. And **`accent`, `secondary`, and `muted` collapse to nearly the
same grey**, so they are mutually indistinguishable in greyscale. That is acceptable only
because none of them carries information by colour alone; verified in §11.5.

**`muted` at 4.87:1 is the AA floor of this palette** and it carries 9pt dates. Do not
change it — lightening fails AA, and darkening inverts the ordering above.

### 4.4 Spacing scale

Single base unit `u = 4pt`. Everything is a multiple.

| Gap | Value |
|---|---|
| Bullet to bullet | `0.5u` (2pt) |
| Line within paragraph | leading 1.35× |
| Entry to entry | `2u` (8pt) |
| Section to section | `3u` (12pt) |
| Rule to first entry | `1.5u` (6pt) |
| Header block to first section | `4u` (16pt) |
| Header block internal lines | `1u` (4pt) |
| Skills row to row | `0.5u` (2pt) |

The last two gaps were implicit before this revision; both are now filled at the grid step
closest to modern-cv's own explicit values — `pad(bottom: 5pt)` on the name block and
`pad(top: 2pt)` per skill row — which is the kind of gap this scale should not leave
undefined (§5.3).

### 4.5 Rules and strokes

Everything here is a vector path (§2.2). Nothing in this section is a character.

| Element | Spec |
|---|---|
| Section rule | 0.6pt solid `accent`, full text-column width |
| Header block rule | 1.2pt solid `accent`, full width |
| Prompt chevron | Two 0.6pt `accent` strokes meeting at a point, drawn in one grid cell |
| Block cursor | Filled `accent` rect, 0.6 em × 0.7 em (one cell, roughly cap-height) |

**Where each mark appears.** The prompt chevron marks the CV's section headers (§6.4) and,
on the cover letter only, the date line (Appendix A). The block cursor marks exactly one
position per document: after the name in the header block (§6.3), and it is reused
unmodified to terminate the footer prompt on both documents (§6.8) — not approximated with
a typed underscore or resized for a different context. A mark rendered at a different size
or in a different form in one place than another is a coherence bug, not a stylistic
variant.

**The grid constraint.** Every drawn mark occupies exactly **one monospace cell** —
0.6 em wide at IBM Plex Mono's advance width — and aligns to the text baseline. This is
what keeps the decoration reading as *terminal* rather than as generic line ornament: the
marks look like characters in the glyph grid that happen to be drawn instead of typed.
A mark that ignores the grid is off-spec even if it looks fine in isolation.

**Stroke weight is shared.** Marks use 0.6pt, identical to the section rule, so chevron
and rule read as one system. Do not tune a mark's weight independently to make it "pop" —
that is the change that breaks the coherence this buys.

**Do not trace letterforms.** Building a `$` or `>` out of line segments produces a crude
glyph and forfeits the font's optical quality. Use geometric marks that belong to the line
system — chevron, bracket, cursor block. Two marks total is the budget.

Drawn lines rather than repeated box-drawing characters, for the same reason: a line of
`═` extracts as dozens of junk characters and reflows badly under font substitution. The
`─` and `═` in this document's mockups denote *rules*, not literal character runs.

### 4.6 Multi-accent lists and the `friggeri` preset (optional)

`accent` may be a **list** instead of a single value — `-V accent=green,red,#076678`, or a named
list preset. Section headers are coloured in document order, indexing into the list and
**wrapping (rolling over)** once the list is exhausted (`heading_index mod list_length`). This
applies to the whole heading — chevron, text, and rule together (§4.5, §6.4) — using the same
colour per heading, unless the first-3-letters scope (§6.4) is also active, in which case only
the heading text's first 3 letters take the per-heading colour; the chevron and rule still get
full colour either way, since they're marks, not text.

Every colour in a custom list must clear the AA floor by the method in §4.2. Custom hexes are the
implementer's job to verify — `friggeri` below is provided pre-verified, a safe zero-work default
the way `red`/`green` already are.

**`friggeri` preset.** A 5-colour rotation inspired by
[gw0/friggeri-cv-letter](https://github.com/gw0/friggeri-cv-letter)'s own accent rotation
(`blue → red → orange → green → purple → brown`, confirmed from its `.cls` source), but retuned:
none of the original hexes clear this spec's AA floor on white except brown (blue `#1ccee8`
1.90:1, red `#fb3179` 3.61:1, orange `#fda12f` 2.04:1, green `#b0d82c` 1.65:1, purple `#a94df3`
4.16:1, brown `≈#964B00` 6.36:1) — copying them verbatim would fail legibility (§2.1) outright for
5 of 6. Same fix as §4.2's green preset: keep each hue, retune lightness at full saturation to the
brightest value that still clears 4.5:1. Brown is dropped from the rotation — retuned, it lands 3°
from retuned orange, the same near-duplicate-hue problem §4.2 found between Gruvbox olive and true
green, so keeping both would just look like two oranges.

| Order | Colour | Hex | Contrast on white |
|---|---|---|---|
| 1 | blue | `#008194` | 4.60:1 |
| 2 | red | `#eb0054` | 4.51:1 |
| 3 | orange | `#ad6000` | 4.72:1 |
| 4 | green | `#628000` | 4.56:1 |
| 5 | purple | `#a638ff` | 4.53:1 |

`-V accent=friggeri` selects this list (§9.3). Dark-web equivalents are out of scope here, same
as the rest of §4.1 — deferred to §10's own spec.

Greyscale (§4.3) is unaffected: which colour a given section gets carries no information, only
decoration, so nothing is lost printing greyscale. The `plain` variant (§9.3) strips this exactly
like a single `accent` — no colour, no list, no scope.

---

## 5. Typography

### 5.1 Families

| Role | Family | Licence |
|---|---|---|
| Chrome — name, section headers, dates, tech tags, skills labels | **IBM Plex Mono** | SIL OFL |
| Body — bullets, prose, job titles, org names | **IBM Plex Sans** | SIL OFL |

Both are SIL OFL, so PDF embedding carries no licensing restriction — unlike several
popular commercial faces whose embedding permissions can cause the recipient to see a
substituted font. They are designed as one family, so the mono/sans pairing is coherent
rather than a collision. IBM Plex Sans appears on ATS-safe font lists.

### 5.2 Why body text is not monospace

Monospace consumes roughly 30–40% more horizontal space than a proportional face at the
same optical size. Setting the whole CV in mono costs approximately a quarter of the
bullet content per page — the same three-line achievement becomes four lines, and either
the CV grows a page or detail gets cut. Detail is the thing that convinces the engineer
reader (§1.2), so it is the wrong thing to spend.

Mono on the chrome delivers the entire aesthetic signal at near-zero density cost, because
headers, dates, and tags are short by nature.

### 5.3 Type scale

Six tiers, anchored on **Body = 10.5pt** — unchanged from before, since it already sits
above the 10pt legibility floor below and is the value §5.5's characters-per-line math is
built on. Everything else is expressed as a ratio against it:

| Tier | × Body | Size | Elements |
|---|---|---|---|
| Footer | 0.76× | 8pt | Footer |
| Meta | 0.86× | 9pt | Contact lines, Dates, Per-role tech line, Skills label |
| Body | 1.00× | 10.5pt | Org · location, Body / bullets, Tagline |
| Emphasis | 1.14× | 12pt | Job title |
| Section header | 1.33× | 14pt | Section header |
| Name | 1.90× | 20pt | Name |

| Element | Family | Size | Weight | Case / tracking | Colour |
|---|---|---|---|---|---|
| Name | Mono | 20pt | Bold | Upper, +0.04em | `fg` |
| Tagline | Sans | 10.5pt | Regular | Sentence | `muted` |
| Contact lines | Mono | 9pt | Regular | — | `fg` |
| Section header | Mono | 14pt | Bold | Upper, +0.08em | `accent` |
| Job title | Sans | 12pt | SemiBold | Sentence | `fg` |
| Org · location | Sans | 10.5pt | Regular | Sentence | `fg` |
| Dates | Mono | 9pt | Regular | — | `muted` |
| Body / bullets | Sans | 10.5pt | Regular | Sentence, leading 1.35 | `fg` |
| Per-role tech line | Mono | 9pt | Regular | — | `muted` |
| Skills label | Mono | 9pt | Medium | — | `accent` |
| Footer | Mono | 8pt | Regular | — | `muted` |

**Why this shape, not just these numbers.** The prior scale had four sizes (9, 9.5, 10.5,
11pt) packed into a narrow band with no clear internal ordering — Job title and Section
header tied at 11pt — then jumped straight to 20pt for Name with nothing between. That's a
flat middle and one unexplained leap. The rescale above was informed by
[modern-cv](https://github.com/ptsouchlos/modern-cv)'s own cascade (name 32 / H1 16 / H2
12 / body 11 / meta 9 / footer 8pt), whose useful property isn't its raw numbers — those
assume a proportional sans face with no ATS/mono-grid constraints — but its *shape*: tight,
near-uniform steps through the reading tiers, then one clearly louder jump at the top.
Reproduced at this document's scale, the step ratios are 8→9 (1.13×), 9→10.5 (1.17×),
10.5→12 (1.14×), 12→14 (1.17×) — four consecutive tight steps — then 14→20 (1.43×), the one
loud jump into Name. Dates and Skills label fold into the Meta tier alongside Contact and
the tech line, since an isolated 9.5pt outlier served no purpose once the tiers were made
explicit. Job title gets its own Emphasis tier clearly above Body, which also reinforces
§6.5's claim that it is the highest-fixation element on the page — it should look like one,
not just be ordered first. Tagline drops to the Body tier: it's a short descriptive
sentence under the name (§6.3), not a fixation-priority element like Job title, so it reads
as running text rather than competing with it for weight. Section header is the deliberate
fix — at 14pt it is unambiguously the second-loudest thing on the page (0.7× of Name, 1.17×
above Emphasis), which is what actually gives it landmark weight; previously it relied on
case, weight, colour, and the rule alone to read as one, because size wasn't doing any of
the work. The chevron and cursor marks in §4.5 are already specified in `em` relative to
the element they sit beside, so they scale with this change automatically. Name stays
**20pt** rather than following modern-cv toward a 1.9–2.9× range: §6.3 hard-requires the
name unbroken on line 1, and IBM Plex Mono's advance width means pushing a long hyphenated
name much past 20pt risks wrapping inside the A4 text column — a considered no-change, not
an oversight.

**Ratios are documented, not implemented.** The table above exists so the design intent is
auditable, but the sizes themselves stay in absolute `pt`, for three reasons specific to
this document. First, the "body text never goes below 10pt" floor below is a physical
print-legibility limit, not a relative one — it has to resolve to an absolute value no
matter what unit the scale is authored in. Second, every other measurement this layout
depends on — page geometry (§6.1, mm), stroke weights (§4.5, pt), the §5.5 measure
calculation — is already absolute; making font size the one relative axis in an otherwise-
absolute system adds a unit-system seam with no matching payoff. Third, Typst resolves `em`
against the nearest enclosing text context, not a fixed document root — if a size is later
set inside a show rule nested inside another sized context (plausible here, since chrome
and body interleave), `em` values would compound silently. That's exactly the kind of
implementation footgun §11.6 says this spec must pre-empt rather than leave for an
implementer to discover.

Body text never goes below 10pt. Below that it becomes hard to read in print and gains
nothing — if the CV does not fit, cut content, do not shrink type.

### 5.4 Ligatures

**Off** in the CV and cover letter. Some fonts map ligatures into the Unicode Private Use
Area rather than emitting proper `ToUnicode` sequences, which breaks copy-paste and text
extraction round-tripping — `fi` comes back as a replacement character or vanishes. The
document must extract exactly as it reads.

Programming ligatures are **allowed in web code blocks**, where extraction fidelity is not
a hiring outcome.

### 5.5 Measure

Target 85–95 characters per line maximum for body text. On A4 with the margins in §6.1
this lands at roughly 92 characters, which is at the upper limit — keep bullets to two or
three lines and use the indent to shorten the effective measure.

---

## 6. CV layout

### 6.1 Page geometry

| Property | A4 | US Letter |
|---|---|---|
| Page | 210 × 297 mm | 216 × 279 mm |
| Top / bottom margin | 16 mm | 16 mm |
| Text column left edge | 24 mm | 25 mm |
| Right margin | 18 mm | 19 mm |
| Mark position | 15 mm from page edge, i.e. 9 mm left of the column | 16 mm |

Both sizes must build from one source. Default to A4 for international applications and
Letter for US-based employers.

**Structural rules:**

- Single column, strictly top-to-bottom.
- No tables, no `grid()`, no text boxes, no sidebars, no floating elements.
- **Nothing in the PDF page header or footer that matters.** Many parsers skip those
  regions entirely. The optional footer (§6.8) is decorative only.
- No raster images and no embedded `image()` files. Marks are drawn with Typst's native
  `line` / `curve` / `rect` primitives — the same graphics operators as the rules, adding
  no new object type to the PDF. An embedded SVG would become a tagged Figure needing alt
  text under PDF/UA-1; a drawn path needs only `pdf.artifact`.

### 6.2 Section order and the page-one midpoint

```
1. Header block          ← name, tagline, contact
2. Summary               ← optional, 2–3 lines
3. Experience            ← strongest, most recent first
4. Projects              ← optional
5. Skills                ← may swap with Projects
6. Education
7. Certifications        ← optional
```

**The midpoint rule.** Recruiter attention concentrates on the upper half of page one, and
job titles draw more fixation than any other element. The strongest job title and the
single biggest quantified outcome must appear **above the vertical midpoint of page one**.
If the current ordering buries them, reorder — this overrides aesthetic balance.

**Length: one or two pages, both fine.** Eye-tracking work indicates page two receives
attention comparable to page one, and pages three onward do not. Do not compress detail to
force a single page; do not pad to fill two. Never exceed two.

### 6.3 Header block

```
    JANE DOE ▮                    ← ▮ is a drawn block cursor, not a character
    Software Engineer · Distributed Systems & ML
    jane@ena.one · +1 555 0100 · Berlin, DE
    ena.one · github.com/jane · linkedin.com/in/jane
    ═══════════════════════════════════════════════════
```

| Rule | Detail |
|---|---|
| **Line 1 is the name. Always.** | Many parsers take the first text line as the candidate name. Nothing — no prompt, no tagline, no contact — may precede it. This is the single hardest rule in the document. |
| Block cursor | One cell after the name, on the name's baseline, `accent`. Legal there **only because it is drawn** — a typed `▮` would land inside the parsed name field (§2.3). Optional; it is the single most recognisable terminal mark, so it earns its place. |
| Contact | Real text, never an image or icon-only. Icons are permitted **only** if the text is also present; the parser ignores the icon and reads the text. Simpler to omit them. |
| Separator | `·` (U+00B7) with spaces. Not `|`, not `•`. |
| URLs | Bare, no `https://`, no `www.`. Hyperlinked, but the visible text must be complete and readable — the parser sees the text, not the link target. |
| Phone | Optional. Include only for markets where it is expected. |
| **Omitted** | Photo, date of birth, nationality, marital status, full postal address. US/international convention; several are discrimination-exposure risks for the employer, which makes their presence a mild negative. |
| Location | City + country only. |
| Rule | 1.2pt `accent`, directly under the block. |

### 6.4 Section header

```
❯   EXPERIENCE
    ───────────────────────────────────────────────────
```

- Drawn prompt chevron at the mark position, `accent`, on the **keyword's baseline** —
  the placement that reads best, available because the mark emits no text (§2.3).
- Header keyword from the closed list in §7.2. Uppercase, mono bold 14pt, `accent`,
  +0.08em tracking.
- 0.6pt `accent` rule, full column width, `0.5u` below the header baseline.
- Extracted text is the keyword alone, on its own line. Verified in §11.2.
- **Optional first-3-letters scope** (`-V accent-scope=first3`, §9.3): colours only the first 3
  letters of the heading keyword in `accent`; the rest renders in `fg`. Mechanism confirmed from
  gw0/friggeri-cv-letter's `\@sectioncolor` macro, which grabs exactly 3 characters via TeX's
  undelimited-parameter argument grabbing (§4.6). Applies to heading text only — the chevron and
  rule stay full `accent` regardless. Recolours existing ATS-lane characters, adds or removes
  none, so §11.2 is unaffected. Combine with `-V accent=friggeri` (§4.6) — both flags set
  explicitly, neither implied by the other — to reproduce "the friggeri style."

### 6.5 Experience entry

```
❯   EXPERIENCE
    ───────────────────────────────────────────────────

    Senior Backend Engineer
    Acme GmbH · Berlin, DE                Jun 2023 – Present
    • Cut p99 ingest latency from 340 ms to 90 ms across 14
      services handling 2M req/day, by replacing the fan-out
      path with a batched consumer.
    • Led migration of the deploy pipeline to Nix, cutting
      median CI time 11 min → 4 min for 40 engineers.

      Go · Rust · Kubernetes · eBPF · PostgreSQL
```

| Element | Spec |
|---|---|
| Job title | Own line, first. Sans SemiBold 12pt. First because it is the highest-fixation element. |
| Org · location · dates | One line. Dates pushed right with `#h(1fr)` — this keeps it a **single line in the content stream**, so extraction order is preserved. |
| Bullets | `•`, hanging indent, 2–3 lines each, 3–5 per role for recent roles and fewer going back. |
| Tech line | Optional, last. Mono 9pt `muted`, `·`-delimited. Raises keyword density and reads as a tag list. Indented `11pt` to match the bullets' hanging indent (`ul.bul`'s `padding-left`), so its left edge lines up with the bullet text rather than the bullet marker. Top margin `1u` (not the `0.5u` used between bullets), so it reads as a distinct trailing element rather than a fourth bullet. |
| Page breaks | An entry must not split across pages with fewer than two bullets on the first part. Prefer moving the whole entry. |

**Date format.** Default `Jun 2023 – Present` — three-letter month, four-digit year,
en dash with spaces. One format for every date in the document, no exceptions; mixing
`Mar 2023`, `03/2023`, and `3-23` is a documented cause of mis-parsed employment history.

ISO 8601 (`2023-06 – present`) is thematically appealing and unambiguous, but month-name
formats are what parsers are tuned for. It is available as an opt-in in the `themed` build
and is flagged as **accepted risk** — do not enable it for a large-employer application.

### 6.6 Skills

```
❯   SKILLS
    ───────────────────────────────────────────────────
    Languages    Go · Rust · Python · C · TypeScript
    ML           PyTorch · JAX · vLLM · Triton · CUDA
    Infra        Kubernetes · Terraform · Nix · eBPF
    Practice     Distributed systems · Observability
```

**Implementation constraint, non-negotiable:** each row is a single line of text —
an inline fixed-width `box()` for the label followed by the values. It must **not** be a
`table()` or `grid()`. A skills table is one of the most common parse failures; Workday in
particular is reported to drop content inside even simple two-column skills tables. The
inline-box construction is visually identical and extracts as
`Languages    Go · Rust · Python · C · TypeScript`.

Label vocabulary follows §3.3 — group the way practitioners group. Do not rate proficiency
(§3.3 banned list). Do not list every technology ever touched; a long list dilutes the
keyword signal it is meant to create.

### 6.7 Projects and Education

**Projects** follow the experience entry structure, with the role line replaced by
`Project name — one-line description` and dates optional. Include a bare URL. Prefer three
substantial entries over eight thin ones.

**Education** is compact: degree, institution, location, dates. One entry per line pair.
Omit GPA unless recent and strong. Coursework lists only if early-career.

### 6.8 Footer

Optional, decorative, artifact-marked, and containing nothing that matters. It may be
omitted entirely from either document — the CV and the cover letter are each free to carry
it or not, independently:

```
        jane@ena:~$ ▮                          page 1 / 2
```

`▮` is the drawn block cursor (§4.5), reused unmodified — not a typed `_`. Mono 8pt
`muted`. Since parsers commonly skip the footer region, this is the one place a literal
prompt string is free of consequence — it is the release valve for the aesthetic.

The cover letter uses this exact same prompt string and mark in its own footer
(Appendix A) — the two documents now share one footer shape rather than the CV having a
footer prompt and the cover letter having a different, riskier top-of-letter one. See
§4.5's mark-reuse rule: this is the one other position the block cursor is legal in.

`page 1 / 2` is CV-only pagination text, orthogonal to the shared prompt string — the
cover letter's footer carries no pagination.

---

## 7. ATS conformance rules

### 7.1 How parsers work

Understanding the pipeline explains every rule below:

```
extract text → segment into blocks by header keyword → parse fields → rank
```

Segmentation keys on section headers. If a header is not recognised, its whole block is
orphaned and the fields inside are never parsed. Ranking then scores the parsed fields —
not the visual document. A parse failure produces a low rank rather than a rejection
notice, which is why the failure is invisible.

### 7.2 Closed section-name vocabulary

Only these. The left column is what renders; the right column lists acceptable
substitutions.

| Canonical | Acceptable variants |
|---|---|
| `SUMMARY` | `PROFESSIONAL SUMMARY` |
| `EXPERIENCE` | `WORK EXPERIENCE`, `PROFESSIONAL EXPERIENCE` |
| `PROJECTS` | `PERSONAL PROJECTS`, `OPEN SOURCE PROJECTS` |
| `SKILLS` | `TECHNICAL SKILLS` |
| `EDUCATION` | — |
| `CERTIFICATIONS` | — |
| `PUBLICATIONS` | — |
| `LANGUAGES` | — |

Every variant contains the canonical keyword as a whole word. **Banned:** `whoami`,
`~/.skills`, `$ ls projects/`, `MY TOOLKIT`, `WHAT I'VE DONE`, `STACK`, `ARSENAL`, and
anything else clever. The aesthetic lives on the rule line, not in the vocabulary.

### 7.3 Checklist

| # | Rule | Evidence |
|---|---|---|
| 1 | Single column, no tables, no text boxes, no sidebars | Strong |
| 2 | Section names from §7.2 only | Strong |
| 3 | Nothing meaningful in page header/footer | Strong |
| 4 | Text-selectable PDF, no images of text | Strong |
| 5 | Contact details as real text at the top, name on line 1 | Strong |
| 6 | One date format throughout | Strong |
| 7 | Standard bullet characters (`•`, `-`) | Moderate |
| 8 | Fonts embedded; no exotic or unembeddable faces | Moderate |
| 9 | Reverse-chronological ordering | Moderate |
| 10 | Keywords from the job description appear in Experience and Skills, in natural prose | Moderate |
| 11 | 0.5–1 inch (13–25 mm) margins | Weak — cosmetic, not a parse factor |

**On evidence quality.** Rows 1–6 are corroborated by how parsers are documented to work
and reproduce across independent reports. Rows 7–10 are widely repeated across
resume-service publications whose test methodology is not independently verifiable —
follow them because they are cheap, not because they are proven. Row 11 is presentation
only. Recorded so future decisions know which rules can be traded away.

### 7.4 Format

**PDF, text-selectable, generated by Typst.** PDFs generated by typesetting engines
extract as cleanly as DOCX in modern systems and preserve layout. Deliver DOCX only when
an application explicitly demands it, and generate the `plain` variant if so.

Verify before every submission by selecting a sentence in a PDF reader. If it does not
highlight as text, the file is an image and will score zero.

---

## 8. PDF output contract

| Property | Value |
|---|---|
| Conformance target | **PDF/UA-1** |
| Tagging | On. Typst 0.14+ writes Tagged PDF by default; the structure tree gives the intended reading order |
| Artifacts | Every human-lane element wrapped in `pdf.artifact` with the most specific artifact kind available |
| Alt text | None required — decoration is drawn paths wrapped in `pdf.artifact`, not images. If a real image is ever added it needs alt text, so don't add one |
| Fonts | Fully embedded, subsetted, ligatures off |
| Metadata `title` | `Jane Doe — Software Engineer — CV` |
| Metadata `author` | Full name |
| Metadata `subject` | Target role |
| Metadata `keywords` | Core technology keywords |
| Filename | `Firstname_Lastname_CV.pdf` / `Firstname_Lastname_CoverLetter.pdf`. No dates, no version numbers, no `final_v3` |

PDF/UA-1 is based on PDF 1.7 and is mutually incompatible with PDF 2.0; it is the target
Typst supports and the one with broader reader compatibility. Typst enforces some
conformance checks at compile time — valid Typst can fail to compile under PDF/UA-1 (for
example if the first heading is not level 1), so the template must be built with the flag
enabled from the start rather than retrofitted.

---

## 9. Build pipeline and variants

### 9.1 Pipeline

```
cv.md ──┬── pandoc --pdf-engine=typst --template=cv.typ ──► cv.pdf
        ├── pandoc --to=html5 --css=cv.css ──────────────► cv.html
        └── pandoc --to=plain ───────────────────────────► cv.txt

letter.md ── same three targets
```

One Markdown source per document. Motifs live entirely in `cv.typ` show rules (§2.5).
Makefile-driven so all outputs rebuild together and cannot drift.

### 9.2 Markdown contract

Show rules can only key off structure, and Markdown's structure is thin. The source must
therefore follow a fixed convention, or the template cannot tell a job title from an
employer. This convention **is** the interface between §6 and the pipeline:

````markdown
---
name: Jane Doe
tagline: Software Engineer · Distributed Systems & ML
email: jane@ena.one
location: Berlin, DE
links: [ena.one, github.com/jane, linkedin.com/in/jane]
---

## Experience

### Senior Backend Engineer
Acme GmbH · Berlin, DE — Jun 2023 – Present

- Cut p99 ingest latency from 340 ms to 90 ms across 14 services...
- Led migration of the deploy pipeline to Nix...

`Go · Rust · Kubernetes · eBPF · PostgreSQL`

## Skills

Languages
: Go · Rust · Python · C · TypeScript

ML
: PyTorch · JAX · vLLM · Triton · CUDA
````

| Source construct | Renders as | Rule |
|---|---|---|
| YAML front matter | Header block (§6.3) | `name` is emitted first, always |
| `## Heading` | Section header + rule + drawn chevron (§6.4) | Text must be in the §7.2 vocabulary — the template should **fail the build** on anything else |
| `### Heading` | Job title, own line | |
| First paragraph after `###` | Org · location line | Split on the last ` — `; the right side becomes the date, pushed right with `#h(1fr)` on the **same line** |
| Bullet list | Bullets (§6.5) | |
| Trailing paragraph that is entirely inline code | Per-role tech line | Mono 9pt `muted` |
| Definition list | Skills rows (§6.6) | Show rule renders term + definition as one line with an inline `box()` label — it must **override** Pandoc's default `#terms` rendering, which lays out as a grid |

The definition-list override is the one item worth verifying first: getting it wrong
silently reintroduces exactly the grid structure §6.6 bans.

### 9.3 Variants

Selected by a Pandoc variable (`-V variant=plain`), never by forking content.

| Variant | Description | When |
|---|---|---|
| `themed` | Default. Drawn marks, accent colour, rules, mono chrome. | Almost always |
| `plain` | Motifs and accent stripped. Black text, plain rules, identical structure and content. | Large-employer portals, known-legacy ATS, DOCX requests, any application where the stakes justify zero risk |
| `txt` | Plain text. | Paste-into-form fields, and as the §11 extraction reference |

`plain` must be a genuine one-flag build. If producing it requires editing content, the
separation in §2.5 has been violated somewhere.

**Multi-accent and the friggeri style, independently.** Two more build variables, both optional
and independent of each other and of `variant`:

- `-V accent=<color>[,<color>...]` or `-V accent=friggeri` — a colour list instead of a single
  preset name (§4.6). Composes with `variant` exactly like a single `accent`: `plain` strips it
  regardless.
- `-V accent-scope=full|first3` — default `full` (today's behaviour, unchanged). `first3` colours
  only a heading's first 3 letters (§6.4).

Neither flag changes the other's default — `accent=friggeri` alone gives the rainbow rotation on
whole headings, `accent-scope=first3` alone gives first-3-letter colouring in whichever single
`accent` is active. To reproduce "the friggeri style," set both explicitly:

```
-V accent=friggeri -V accent-scope=first3
```

Both remain genuine one-flag-each builds — no template or content edits, same rule as switching
`accent` today.

**Accent selection is a second, independent variable.** `-V accent=green` (default) or
`-V accent=red` selects which row of the §4.1 preset table the template resolves
`accent` to. It composes freely with `variant`: `themed` + either accent produces a
coloured document, `plain` ignores `accent` entirely since it strips colour. Exactly like
`plain`, switching accent must be a genuine one-flag build — no template or content edits.
If producing the other preset requires touching `cv.typ` beyond the flag, the token
indirection in §4.1 has been violated.

### 9.4 Version pinning

Pandoc's Typst output template and Typst's own APIs have both changed in ways that broke
existing templates across minor releases. **Pin exact versions of both tools**, record
them in the repository, and treat an upgrade as a change requiring a full §11 re-run.

Minimum: Typst **0.14** (tagged PDF by default, `pdf.artifact` available).

---

## 10. Web token bridge

Brief by design — the homepage and blog get their own spec. What must hold:

- **Semantic CSS custom properties** (`--bg`, `--fg`, `--accent`, `--muted`,
  `--secondary`, `--surface`), one palette file per theme. No hex values at call sites.
  Same token names as §4.1, so the CV and the site are provably the same system.
- **Dark is the default**, Gruvbox Dark with the *bright* accent set from whichever preset
  is selected — bright green `#b8bb26` by default, bright orange `#fe8019` under the `red`
  preset (`-V accent=red`, §9.3, §4.1). The light theme uses white `#ffffff` and the matching
  *faded*/custom-tuned set — **identical to the CV**, so the PDF and the light-mode web
  page are the same document in two media, whichever preset is active. Cream `#fbf1c7`
  appears only as `--surface` for code blocks and panels (§4.2).
- **Never accent-on-accent.** Terminal palettes assume text sits on the base background;
  accent pairings are untested for contrast and generally fail.
- **Decorative prompts are `aria-hidden`.** The document underneath must be real headings
  and landmarks. A screen reader should never hear `jane@ena:~$ cat about.md`.
- **Honour `prefers-reduced-motion`.** Blinking cursors, typewriter reveals, and
  streaming-token effects are the signature move of this aesthetic and the most common
  accessibility failure in it. All three must have a static fallback.
- **Code blocks** use an accessibility-checked syntax theme, not a terminal scheme ported
  directly — stock terminal palettes routinely fail contrast checks for small text.
- Body text uses the brightest foreground token. Mid-tone accents are for decoration and
  large headings only.
- The CV is published as a page **and** linked as a PDF, both built from the same source.

---

## 11. Verification checklist

Run in full before the first submission, and again after any tooling upgrade (§9.4).

### 11.1 Build

- [ ] `make` produces `cv.pdf`, `cv.html`, `cv.txt` and the letter equivalents, no warnings
- [ ] `themed` and `plain` both build from one source with no content edits
- [ ] A4 and Letter both build

### 11.2 Extraction — the critical test

- [ ] `pdftotext -layout cv.pdf -` and read the output
- [ ] Every section keyword from §7.2 appears **on its own line**
- [ ] Sections appear in the same order as on the page
- [ ] The extraction contains **no decoration at all** — no chevron, no cursor, no rule
      characters. Decoration is drawn (§2.2), so anything decorative appearing in the text
      stream means a mark was typed instead of drawn. Run this check first
- [ ] The name is the first non-empty line, with nothing prepended
- [ ] Email, phone, and URLs appear as complete strings
- [ ] Each skills row extracts as one line with its label and values intact — if a label
      and its values land on separate lines, the definition-list show rule (§9.2) fell
      back to a grid
- [ ] Each experience entry's org and dates extract on one line
- [ ] Section keywords and entry order match `cv.txt`. Do not expect a clean `diff` —
      `--to=plain` will not reproduce right-aligned dates or the rules; compare content
      and order, not layout

### 11.3 Parsing

- [ ] Upload to 2–3 independent ATS simulators; all identify name, contact, every section,
      and every employment entry with correct dates
- [ ] Text selection works in a PDF reader (§7.4)
- [ ] Copy-paste a ligature-prone string (`fi`, `fl`, `ffi`) and confirm exact round-trip

### 11.4 Accessibility and conformance

- [ ] Validate with **veraPDF** against declared PDF/UA-1 — no errors
- [ ] Screen reader reads the document in visual order and announces no marks or rules
- [ ] Every colour pair in use matches §4.1 and meets its stated threshold, in **both**
      themes — recompute rather than trusting the table; two of the stock Gruvbox values
      fail AA and were replaced for exactly this reason (§4.2)

### 11.5 Human factors

- [ ] Print greyscale at 100% scale: nothing informational is lost, hierarchy still reads
- [ ] In the greyscale print, section headers read heavier than dates (the accent/muted
      luminance ordering in §4.3 held)
- [ ] Print colour at 100%: accent reproduces acceptably, no ink-heavy backgrounds
- [ ] Strongest job title and biggest metric sit above the page-one midpoint (§6.2)
- [ ] Body text ≥10pt; no line exceeds ~95 characters
- [ ] Document is 1–2 pages; no orphaned entry heading at a page break
- [ ] CV and cover letter placed side by side read as one system
- [ ] Cover letter is 250–400 words, paragraphs of 2–4 sentences
- [ ] Filenames match §8

### 11.6 Review

- [ ] An implementer can build from this spec without asking follow-up questions
- [ ] Every decorative element is a vector path from §4.5, is artifact-marked, sits on the
      monospace grid, and uses the shared 0.6pt stroke weight

---

## Appendix A — Cover letter layout

```
    JANE DOE
    Software Engineer · Distributed Systems & ML
    jane@ena.one · ena.one · github.com/jane
    ═══════════════════════════════════════════════════

    ❯   21 August 2026

        Dear Hiring Manager,

        [1 · Hook — why this role, why now. The introduction is the
         highest-impact paragraph; open with the specific thing, not
         with "I am writing to apply for".]

        [2 · Proof — one achievement in depth. Decisions, trade-offs,
         and context the CV cannot carry. Not a restatement.]

        [3 · Company-specific, 2–3 sentences. Reference a real
         engineering blog post, open-source contribution, or launch.]

        [4 · Close, 2 sentences, with a direct ask for a conversation.]

        Best regards,
        Jane Doe

    jane@ena:~$ ▮                                 ← footer, identical to §6.8
```

| Property | Spec |
|---|---|
| Header block | Identical geometry and tokens to §6.3, so the pair reads as one system. No prompt line beside or below it — the §6.3 name-on-line-1 rule holds here too, with no exception |
| Length | 250–400 words. Below 250 reads thin; above 500 reads self-indulgent |
| Paragraphs | 2–4 sentences, single-spaced, blank line between, left-aligned (never justified) |
| Salutation | `Dear Hiring Manager,` is the preferred generic form and is fine. A named salutation is a weak signal — do not spend research effort on it |
| Date | Long form, matching the CV's language conventions. Marked with the drawn prompt chevron (§4.5), the same mark the CV uses beside its section headers — the letter's one header-like line |
| Content rule | Add what the CV cannot carry. The reader just read the CV; prose restatement wastes the only paragraph they will finish |
| Footer | Optional (§6.8). Identical string and marks to the CV's footer — no company-specific customization; that content lives in paragraph 3 instead |

---

## Appendix B — Decisions log

| Decision | Choice | Rationale |
|---|---|---|
| Aesthetic intensity | Medium — prompt motifs, ASCII rules, mono chrome | Full terminal skin (dark background, boxed panels) is unprintable and risks a conservative reviewer; restrained loses the identity |
| Body typography | Mono chrome, sans body | Mono body costs ~25% of bullet content per page (§5.2) |
| Palette | Gruvbox, **faded set on white**, accent as a **selectable preset** (`red`/`green`, §4.1) | Gruvbox's light variant is tuned for cream; the faded/custom-tuned accent set is the part that clears AA on white paper (§4.2). One accent value per preset, no size-dependent variants; choosing the preset is a one-flag build (§9.3), not a one-time fixed decision |
| Preset naming | `orange` renamed to `red` | The faded-orange print value (`#af3a03`) and its bright-web counterpart read as red in practice, not orange; the label was corrected to match |
| Green preset hex | `#137200` revised to `#157d00` (brighter shade, same ~110° hue) | Requested change; contrast on white drops from 6.11:1 to 5.29:1 — still clears the 4.5:1 AA-any-size floor with headroom, but noticeably less than the red preset's 6.12:1 (§4.2, §4.3) |
| Block cursor size | `0.6 em × 0.62 em` (x-height) revised to `0.6 em × 0.7 em` (roughly cap-height) | Requested change, to read as a more realistic terminal block cursor. An intermediate `0.8 em` value was tried first and reverted — it overshot IBM Plex Mono's cap-height, so the mark's top stuck up above the capital letters in the (all-caps) name, reading as floating/misaligned even though its bottom edge was still correctly flush with the baseline. `0.7 em` stays within the letterforms' envelope. Still one grid cell wide, still `accent`-filled (§4.5) |
| Pipeline | Markdown → Pandoc → Typst | Single source of truth; enforces the ATS lane by construction (§2.5) |
| Market conventions | US / international English | No photo, no personal data, standard section names |
| Motif strategy | One grammar (terminal), three dialects | Prevents the three-theme mush (§3.1) |
| Decoration form | **Drawn vector paths, not characters** | Emits no text, so extraction risk disappears entirely and marks can sit wherever they look best; also matches stroke weight to the rules and drops the font dependency (§2.3) |
| Mark placement | Beside the section keyword, on its baseline | Only safe because marks are drawn. A *typed* sigil there merges into the keyword's extracted line, and a left gutter does not help — extractors break lines on y-position (§2.3) |
| Console-prompt placement | Footer only, on both documents — the cover letter's former top-of-letter letterhead prompt is removed, not replaced | Artifact-marking only protects against *conformant* tools; a naive ATS text-extractor ignores structure tags and scrapes every character regardless of tagging, so a typed prompt at the top of the letter was never actually zero-risk despite being artifact-marked. The footer is the one zone parsers are documented to skip outright, so relocating there (matching §6.8) removes the risk instead of just moving it, and gives both documents the same footer shape instead of one CV footer plus one letterhead exception (§2.2) |
| Date format | `Jun 2023 – Present` | Month-name formats are what parsers are tuned for; ISO available as flagged-risk opt-in |
| Length | 1–2 pages | Page two gets comparable recruiter attention; compressing costs the engineer reader |
| Footer customization | Dropped — cover letter footer is now identical to the CV's, no company path | Company-specific content already lives in the letter body (Appendix A, paragraph 3); duplicating it in a decorative, parser-skipped footer created a difference between the two footers without adding hiring value |
| Type scale rescale | Full 6-tier cascade rebuilt as ratios of Body (10.5pt anchor); Dates/Skills label folded 9.5→9pt, Job title raised 11→12pt, Section header raised 11→14pt, Tagline dropped 11→10.5pt | Prior scale had a flat 9–11pt middle with Job title and Section header tied at 11pt, then one unexplained jump to Name; modern-cv's cascade showed the useful shape is tight near-uniform steps through the reading tiers plus one loud jump at the top, not its raw numbers (§5.3). Sizes stay in `pt`, not `em` — `em` resolves against the nearest enclosing text context in Typst and would compound silently if nested inside another sized show rule, a correctness risk with no offsetting benefit here |

---

## Appendix C — Sources

- [ATS-Friendly Resume Formatting: Complete Parsing Rules for 2026](https://cv4me.pro/blog/ats-friendly-resume-formatting-2026)
- [Why ATS Tables and Columns Break Your Resume Parsing in 2026 — Jobscan](https://www.jobscan.co/blog/resume-tables-columns-ats/)
- [Resume Formatting Rules ATS Never Forgives — Hireflow](https://hireflow.net/blog/resume-formatting-rules-ats-never-forgives)
- [Ladders 7.4-Second Resume Eye-Tracking Study (2018)](https://www.theladders.com/static/images/basicSite/pdfs/TheLadders-EyeTracking-StudyC2.pdf)
- [Eye-Tracking: Recruiters Average 7.4 Seconds Reviewing a Résumé — HR Daily Advisor](https://hrdailyadvisor.hci.org/2018/11/15/eye-tracking-recruiters-average-7-4-seconds-reviewing-a-resume/)
- [Typst 0.14: Now accessible](https://typst.app/blog/2025/typst-0.14/)
- [Typst Accessibility Guide](https://typst.app/docs/guides/accessibility/)
- [Typst `pdf.artifact` reference](https://typst.app/docs/reference/pdf/artifact/)
- [Typst: How to create accessible PDFs from the start](https://typst.app/blog/2025/accessible-pdf/)
- [PDF4: Hiding decorative images with the Artifact tag — W3C WCAG Techniques](https://www.w3.org/TR/WCAG20-TECHS/PDF4.html)
- [Using Pandoc and Typst to Produce PDFs — imaginarytext.ca](https://imaginarytext.ca/posts/2024/pandoc-typst-tutorial/)
- [A New Typst Template for Pandoc — imaginarytext.ca](https://imaginarytext.ca/posts/2025/typst-templates-for-pandoc/)
- [Typst with Pandoc: A Modern, Fast Alternative to (Xe)LaTeX](https://slhck.info/software/2025/10/25/typst-pdf-generation-xelatex-alternative.html)
- [Best Resume Fonts 2026: ATS-Tested — Resume Optimizer Pro](https://resumeoptimizerpro.com/blog/best-resume-fonts)
- [gruvbox — original palette README](https://github.com/lcividinwork/gruvbox/blob/master/README.md)
- [Best US Cover Letter Length in 2026 — Hireflow](https://hireflow.net/blog/best-us-cover-letter-length-in-2026)
- [Cover Letter Statistics (Hiring Manager Survey) — Resume Genius](https://resumegenius.com/blog/cover-letter-help/cover-letter-statistics)
- [ericwbailey/a11y-syntax-highlighting](https://github.com/ericwbailey/a11y-syntax-highlighting)
- [ptsouchlos/modern-cv — Typst CV template](https://github.com/ptsouchlos/modern-cv)
