"""ATS-extraction acceptance checks against the built example PDFs, using
two independent extraction libraries (pypdf, pymupdf) so a pass isn't an
artifact of one library's own quirks. Checks: linear reading order (name
first, this package's own example section names each on their own line, in
document order), intact contact strings, no private-use-area/replacement
glyphs, no decorative characters leaked into the text stream, and
cross-workflow parity (the .typ example and the .md example extract
identically). One file, two entry points: a --all CLI for ad-hoc runs, and
pytest-discoverable functions for CI.
"""

import argparse
import sys
from pathlib import Path

import pymupdf
import pypdf

EXAMPLES = Path(__file__).resolve().parent.parent / "examples"

CV_NAME = "SARAH CONNOR"
SECTION_ORDER = [
    "SUMMARY",
    "EXPERIENCE",
    "SKILLS",
    "EDUCATION",
    "PROJECTS",
    "CERTIFICATIONS, AWARDS & PUBLICATIONS",
]
CONTACT_STRINGS = ["sarah@sconnor.dev", "Austin, TX (US)"]

# Decorative glyphs that must never leak into the extracted text stream —
# every decorative mark (chevron/cursor/rule) is drawn geometry wrapped in
# pdf.artifact(), so none of these should ever appear.
DECORATIVE_CHARS = "❯▮★■➤✓◆➔⚡"

CV_PDFS = {
    "typst": EXAMPLES / "typst" / "cv.pdf",
    "markdown": EXAMPLES / "markdown" / "cv.pdf",
}
LETTER_PDFS = {
    "typst": EXAMPLES / "typst" / "letter.pdf",
    "markdown": EXAMPLES / "markdown" / "letter.pdf",
}
ALL_PDFS = list(CV_PDFS.values()) + list(LETTER_PDFS.values())


def extract_pypdf(path: Path) -> str:
    reader = pypdf.PdfReader(str(path))
    return "\n".join(page.extract_text() for page in reader.pages)


def extract_pymupdf(path: Path) -> str:
    doc = pymupdf.open(str(path))
    return "\n".join(page.get_text(sort=True) for page in doc)


EXTRACTORS = {"pypdf": extract_pypdf, "pymupdf": extract_pymupdf}


def lines_of(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def check_name_is_first_line(path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        first = lines_of(extractor(path))[0]
        if CV_NAME not in first.upper():
            return False, f"[{extractor_name}] first line was {first!r}, expected to contain {CV_NAME!r}"
    return True, "name is the first extracted line under both extractors"


def check_sections_in_order(path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        text_lines = lines_of(extractor(path))
        upper_lines = [l.upper() for l in text_lines]
        last_index = -1
        for name in SECTION_ORDER:
            if name not in upper_lines:
                continue  # not every section appears in every example variant
            index = upper_lines.index(name)
            if index <= last_index:
                return False, f"[{extractor_name}] section {name!r} out of order"
            last_index = index
    return True, "section headings appear each on their own line, in document order"


def check_no_decorative_chars(path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        text = extractor(path)
        leaked = [c for c in DECORATIVE_CHARS if c in text]
        if leaked:
            return False, f"[{extractor_name}] leaked decorative chars: {leaked}"
    return True, "no decorative characters leaked into extracted text"


def check_no_pua_or_replacement_chars(path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        text = extractor(path)
        bad = [c for c in text if c == "�" or 0xE000 <= ord(c) <= 0xF8FF]
        if bad:
            return False, f"[{extractor_name}] found private-use-area/replacement glyphs: {bad!r}"
    return True, "no private-use-area or replacement glyphs"


def check_contact_strings_intact(path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        text = " ".join(lines_of(extractor(path)))
        missing = [s for s in CONTACT_STRINGS if s not in text]
        if missing:
            return False, f"[{extractor_name}] contact strings not intact: {missing}"
    return True, "contact strings extract as unbroken substrings"


def check_cross_workflow_parity(typst_path: Path, markdown_path: Path) -> tuple[bool, str]:
    for extractor_name, extractor in EXTRACTORS.items():
        a, b = extractor(typst_path), extractor(markdown_path)
        if a != b:
            for i, (ca, cb) in enumerate(zip(a, b)):
                if ca != cb:
                    return False, f"[{extractor_name}] diverges at offset {i}: {a[max(0,i-20):i+20]!r} vs {b[max(0,i-20):i+20]!r}"
            return False, f"[{extractor_name}] extracted text differs in length ({len(a)} vs {len(b)})"
    return True, "typst and markdown examples extract identically"


def all_checks() -> list[tuple[str, bool, str]]:
    results = []
    for path in ALL_PDFS:
        label = f"{path.parent.name}/{path.name}"
        for check_name, check_fn in (
            ("name-first-line", check_name_is_first_line),
            ("sections-in-order", check_sections_in_order),
            ("no-decorative-chars", check_no_decorative_chars),
            ("no-pua-replacement-chars", check_no_pua_or_replacement_chars),
        ):
            ok, detail = check_fn(path)
            results.append((f"{label} [{check_name}]", ok, detail))
    ok, detail = check_contact_strings_intact(CV_PDFS["typst"])
    results.append(("examples/typst/cv.pdf [contact-strings]", ok, detail))
    ok, detail = check_cross_workflow_parity(CV_PDFS["typst"], CV_PDFS["markdown"])
    results.append(("cv.pdf [cross-workflow-parity]", ok, detail))
    ok, detail = check_cross_workflow_parity(LETTER_PDFS["typst"], LETTER_PDFS["markdown"])
    results.append(("letter.pdf [cross-workflow-parity]", ok, detail))
    return results


# ---- pytest-discoverable wrappers ----------------------------------------


def test_cv_name_is_first_line():
    for path in CV_PDFS.values():
        ok, detail = check_name_is_first_line(path)
        assert ok, detail


def test_letter_name_is_first_line():
    for path in LETTER_PDFS.values():
        ok, detail = check_name_is_first_line(path)
        assert ok, detail


def test_sections_in_order():
    for path in CV_PDFS.values():
        ok, detail = check_sections_in_order(path)
        assert ok, detail


def test_no_decorative_chars_leak():
    for path in ALL_PDFS:
        ok, detail = check_no_decorative_chars(path)
        assert ok, detail


def test_no_pua_or_replacement_chars():
    for path in ALL_PDFS:
        ok, detail = check_no_pua_or_replacement_chars(path)
        assert ok, detail


def test_contact_strings_intact():
    ok, detail = check_contact_strings_intact(CV_PDFS["typst"])
    assert ok, detail


def test_cross_workflow_parity_cv():
    ok, detail = check_cross_workflow_parity(CV_PDFS["typst"], CV_PDFS["markdown"])
    assert ok, detail


def test_cross_workflow_parity_letter():
    ok, detail = check_cross_workflow_parity(LETTER_PDFS["typst"], LETTER_PDFS["markdown"])
    assert ok, detail


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="run every ATS extraction check")
    parser.parse_args()

    ok = True
    for name, passed, detail in all_checks():
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<50} {detail}")
        ok = ok and passed
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
