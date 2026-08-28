#!/usr/bin/env python3
"""Automated ATS-style acceptance check (mvp spec §12, design-cyber.md §11.2).

Extracts text from a compiled CV PDF with two independent extractors
(pypdf and pymupdf) and asserts:

  (a) it reads in the correct linear order: name -> contact -> summary ->
      experience -> ... (section keywords appear in document order)
  (b) it contains no orphaned/unprintable glyphs from icon fonts (no
      private-use-area codepoints, no replacement characters)
  (c) the closed-vocabulary section names (design-cyber.md §7.2) appear
      as plain extractable text, each identifiable on its own
  (d) the name is the first non-empty line, with nothing prepended
  (e) email/phone/URLs extract as complete, unbroken strings
  (f) no decorative glyph (chevron/cursor/rule characters) leaked into
      the text stream — decoration must be drawn, not typed
      (design-cyber.md §2.2)

This mirrors design-cyber.md §11's "extraction reference" as a repeatable,
automatable check rather than a manual one.

Usage:
  scripts/ats_check.py examples/typst/cv.pdf
  scripts/ats_check.py --all
"""
import argparse
import pathlib
import sys

import pypdf
import pymupdf

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent

SECTION_VOCAB = [
    "SUMMARY", "EXPERIENCE", "PROJECTS", "SKILLS", "EDUCATION",
    "CERTIFICATIONS",
]

# Banned decorative glyphs (design-cyber.md §3.5) — must never appear as
# extractable characters; decoration is drawn, not typed.
BANNED_GLYPHS = "★■➤✓❯◆➔⚡"

EXPECTED_CONTACT = {
    "email": "sarah.connor@ena.one",
    "phone": "+1 555 0142",
}


def extract_pypdf(pdf_path: pathlib.Path) -> str:
    reader = pypdf.PdfReader(str(pdf_path))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def extract_pymupdf(pdf_path: pathlib.Path) -> str:
    doc = pymupdf.open(str(pdf_path))
    return "\n".join(page.get_text() for page in doc)


def check(label, condition, detail=""):
    status = "PASS" if condition else "FAIL"
    print(f"  [{status}] {label}" + (f" — {detail}" if detail and not condition else ""))
    return condition


def run_checks(pdf_path: pathlib.Path) -> bool:
    print(f"\n=== {pdf_path.relative_to(REPO_ROOT)} ===")
    ok = True

    text_pypdf = extract_pypdf(pdf_path)
    text_pymupdf = extract_pymupdf(pdf_path)

    for label, text in (("pypdf", text_pypdf), ("pymupdf", text_pymupdf)):
        print(f" -- extractor: {label} --")
        lines = [l for l in text.splitlines() if l.strip()]

        # (d) name is the first non-empty line, nothing prepended.
        first_line = lines[0].strip() if lines else ""
        ok &= check(
            "name is the first non-empty line",
            first_line.upper().startswith("SARAH CONNOR"),
            f"got {first_line!r}",
        )

        # (a) section keywords appear, in document order.
        positions = []
        for kw in SECTION_VOCAB:
            idx = text.find(kw)
            ok &= check(f"section keyword {kw!r} present", idx != -1)
            positions.append(idx)
        present = [p for p in positions if p != -1]
        ok &= check(
            "section keywords appear in document order",
            present == sorted(present),
        )

        # (c) each section keyword is identifiable on its own line (not
        # merged into a longer run of unrelated text on both sides).
        for kw in SECTION_VOCAB:
            found_clean = any(line.strip() == kw for line in lines)
            ok &= check(f"{kw!r} extracts as its own line", found_clean)

        # (e) contact details extract as complete strings.
        for field, value in EXPECTED_CONTACT.items():
            ok &= check(f"{field} extracts intact ({value!r})", value in text)

        # (b) no unprintable / private-use-area glyphs (icon font leakage).
        pua = [ch for ch in text if 0xE000 <= ord(ch) <= 0xF8FF]
        ok &= check(
            "no private-use-area glyphs (icon font leakage)",
            not pua,
            f"found {pua!r}",
        )
        replacement = text.count("�")
        ok &= check(
            "no replacement characters",
            replacement == 0,
            f"found {replacement}",
        )

        # (f) no banned decorative glyphs typed into the stream.
        banned_found = sorted(set(ch for ch in text if ch in BANNED_GLYPHS))
        ok &= check(
            "no decorative glyphs leaked into text stream",
            not banned_found,
            f"found {banned_found!r}",
        )

    return ok


def find_pdfs():
    return sorted(REPO_ROOT.glob("examples/*/cv*.pdf"))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("pdf", nargs="?", type=pathlib.Path)
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()

    targets = find_pdfs() if args.all else [args.pdf] if args.pdf else []
    if not targets:
        ap.error("give a PDF path or --all")

    all_ok = True
    for pdf in targets:
        all_ok &= run_checks(pdf)

    print()
    print("RESULT:", "PASS" if all_ok else "FAIL")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
