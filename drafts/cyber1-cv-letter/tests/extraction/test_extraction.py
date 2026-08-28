#!/usr/bin/env python3
"""Extraction verification — spec/20260828-mvp.md §12, adapted from
design-cyber §11.2 / rev-modern-cv R2.4.

This is the one test that measures what an ATS actually sees. It simulates
a naive ATS text extractor with two independent libraries rather than
shelling out to pdftotext:

  - pypdf's default extract_text() reconstructs reading order from glyph
    position, merging text drawn in separate content-stream operations
    (e.g. a fixed-width label box next to a value) onto one line when they
    share a baseline.
  - pymupdf's get_text(sort=True) does the same via a different algorithm,
    as a cross-check. pymupdf's *default* (unsorted) mode groups text by
    content-stream block order instead of visual position, which is not
    representative of how position-aware ATS parsers read a page — it is
    deliberately not used for line-adjacency assertions here (verified
    empirically while building this template; see commit history).

Run via `make test` (builds examples/ first), or directly once examples/
is built via `make examples`.
"""
import re
import sys
from pathlib import Path

import pymupdf
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
EXAMPLES = ROOT / "examples"

SECTION_VOCAB = {"SUMMARY", "EXPERIENCE", "SKILLS", "EDUCATION", "CERTIFICATIONS"}
DECORATION_CHARS = "❯▮"

failures: list[str] = []


def fail(msg: str) -> None:
    failures.append(msg)
    print(f"  FAIL: {msg}")


def ok(msg: str) -> None:
    print(f"  ok:   {msg}")


def pypdf_text(pdf: Path) -> str:
    reader = PdfReader(str(pdf))
    return "\n".join(page.extract_text() for page in reader.pages)


def pymupdf_text(pdf: Path) -> str:
    doc = pymupdf.open(str(pdf))
    return "\n".join(page.get_text(sort=True) for page in doc)


def lines_of(text: str) -> list[str]:
    return [l.strip() for l in text.splitlines() if l.strip()]


def check_cv(pdf: Path, *, expect_logo_cell: bool) -> None:
    print(f"\n{pdf.relative_to(ROOT)}")
    text_pypdf = pypdf_text(pdf)
    text_mupdf = pymupdf_text(pdf)
    lines = lines_of(text_pypdf)

    # Name is line 1, nothing prepended.
    if lines and lines[0] == "SARAH CONNOR":
        ok("name is the first extracted line")
    else:
        fail(f"expected 'SARAH CONNOR' as first line, got {lines[0] if lines else '(empty)'!r}")

    # Section keywords each on their own line, in order.
    found_sections = [l for l in lines if l in SECTION_VOCAB]
    expected_order = ["SUMMARY", "EXPERIENCE", "SKILLS", "EDUCATION", "CERTIFICATIONS"]
    if found_sections == expected_order:
        ok(f"section keywords present, own line, in order: {found_sections}")
    else:
        fail(f"section order mismatch: got {found_sections}, expected {expected_order}")

    # No decoration characters anywhere in the extracted text.
    for ch in DECORATION_CHARS:
        if ch in text_pypdf or ch in text_mupdf:
            fail(f"decoration character {ch!r} leaked into extracted text")
    else:
        ok("no drawn-mark characters (chevron/cursor) in extracted text")

    # Entry title + date adjacent, in order (pypdf merges the h(1fr) line).
    if re.search(r"Senior AI Security Engineer\s+Jun 2023", text_pypdf):
        ok("entry 1 title/date adjacent and in order")
    else:
        fail("entry 1 title/date not found adjacent")

    # Org/location line intact and adjacent to the title/date line
    # (org left, location right-aligned via h(1fr) — no longer joined by a
    # " · " separator, so check adjacency the same way as title/date above).
    if re.search(r"Cyberdyne Systems\s+Los Angeles, CA", text_pypdf):
        ok("entry 1 org/location line intact")
    else:
        fail("entry 1 org/location line corrupted or missing")

    # Skills rows: label and values on one line (pypdf / sorted pymupdf).
    for label, needle in [
        ("Detection", "Detection Adversarial example detection"),
        ("Adversarial ML", "Adversarial ML Prompt injection"),
        ("Infra", "Infra Kubernetes"),
    ]:
        if needle in re.sub(r"\s+", " ", text_pypdf):
            ok(f"skills row '{label}' extracts as one line (pypdf)")
        else:
            fail(f"skills row '{label}' did not extract as one line (pypdf)")
        if needle in re.sub(r"\s+", " ", text_mupdf):
            ok(f"skills row '{label}' extracts as one line (pymupdf sort=True)")
        else:
            fail(f"skills row '{label}' did not extract as one line (pymupdf sort=True)")

    # Logo grid must not corrupt the Org | Location line (§5 residual risk).
    if expect_logo_cell:
        if "logos/cyberdyne" in text_pypdf or "logos/cyberdyne" in text_mupdf:
            fail("a raw image path leaked into extracted text (logo not rendered as an image)")
        else:
            ok("no raw image path leaked into extracted text")
        org_line = next((l for l in lines if l.startswith("Cyberdyne Systems")), "")
        if "[" in org_line or "]" in org_line:
            fail(f"stray bracket artifact leaked into the org/location line: {org_line!r}")
        else:
            ok("no stray bracket artifacts in the org/location line")


def check_letter(pdf: Path) -> None:
    print(f"\n{pdf.relative_to(ROOT)}")
    text = pypdf_text(pdf)
    lines = lines_of(text)
    if lines and lines[0] == "SARAH CONNOR":
        ok("name is the first extracted line")
    else:
        fail(f"expected 'SARAH CONNOR' as first line, got {lines[0] if lines else '(empty)'!r}")

    for ch in DECORATION_CHARS:
        if ch in text:
            fail(f"decoration character {ch!r} leaked into extracted text")
    else:
        ok("no drawn-mark characters in extracted text")

    body_start = text.find("Dear Hiring Manager,")
    body = text[body_start:] if body_start != -1 else text
    word_count = len(body.split())
    if 250 <= word_count <= 400:
        ok(f"letter body word count in range: {word_count}")
    else:
        fail(f"letter body word count out of the 250-400 target range: {word_count}")


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def check_cross_workflow_parity() -> None:
    print("\ncross-workflow parity (typst/cv.pdf vs markdown/cv.pdf)")
    a = normalize(pypdf_text(EXAMPLES / "typst" / "cv.pdf"))
    b = normalize(pypdf_text(EXAMPLES / "markdown" / "cv.pdf"))
    if a == b:
        ok("direct-Typst and Markdown+Pandoc CV builds extract identically")
    else:
        # Report the first point of divergence rather than the whole diff.
        for i, (ca, cb) in enumerate(zip(a, b)):
            if ca != cb:
                fail(f"extraction diverges at offset {i}: ...{a[max(0,i-30):i+30]!r} vs ...{b[max(0,i-30):i+30]!r}")
                break
        else:
            fail(f"extraction lengths differ: {len(a)} vs {len(b)} characters")


def main() -> int:
    if not EXAMPLES.exists():
        print("examples/ not found — run `make examples` first", file=sys.stderr)
        return 1

    check_cv(EXAMPLES / "typst" / "cv.pdf", expect_logo_cell=False)
    check_cv(EXAMPLES / "markdown" / "cv.pdf", expect_logo_cell=False)
    check_cv(EXAMPLES / "typst" / "cv-friggeri.pdf", expect_logo_cell=True)
    check_cv(EXAMPLES / "markdown" / "cv-friggeri.pdf", expect_logo_cell=True)
    check_letter(EXAMPLES / "typst" / "letter.pdf")
    check_letter(EXAMPLES / "markdown" / "letter.pdf")
    check_cross_workflow_parity()

    print(f"\n{'=' * 60}")
    if failures:
        print(f"{len(failures)} check(s) FAILED")
        return 1
    print("All extraction checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
