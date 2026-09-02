"""Rendered-layout regression check: every text span's page, position and
string in each built example PDF, compared against a committed baseline.

The other checks in this directory verify properties of the source (that a
spacing token is a literal multiple of the base unit) or of the extracted
text (reading order, contact strings). Neither notices when a rendering
change silently moves things on the page — a mechanism change that leaves a
code line 0.9pt further right, or accumulates a fraction of a point per
entry, passes all of them. This check is the one that fails on it.

Regenerate deliberately, never reflexively: `--update` rewrites the baseline
to whatever the current code produces, so it should be run only after the
new output has actually been looked at.
"""

import argparse
import json
import sys
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "examples"
BASELINE = Path(__file__).resolve().parent / "layout_baseline.json"

PDFS = [
    EXAMPLES / workflow / f"{name}.pdf"
    for workflow in ("typst", "markdown")
    for name in ("cv", "cv-plain", "cv-friggeri", "letter")
]

# Positions are compared at 0.01pt; anything at or below this is rounding in
# the PDF writer rather than a layout change.
TOLERANCE = 0.011


def spans(path: Path) -> list[list]:
    """Every text span as [page, x0, y0, text], in document order."""
    doc = pymupdf.open(str(path))
    out = []
    for page_number, page in enumerate(doc):
        for block in page.get_text("dict")["blocks"]:
            for line in block.get("lines", []):
                for span in line["spans"]:
                    out.append([
                        page_number,
                        round(span["bbox"][0], 2),
                        round(span["bbox"][1], 2),
                        span["text"],
                    ])
    return out


def current_fingerprint() -> dict[str, list[list]]:
    return {str(path.relative_to(ROOT)): spans(path) for path in PDFS}


def load_baseline() -> dict[str, list[list]]:
    if not BASELINE.exists():
        raise AssertionError(
            f"no layout baseline at {BASELINE.relative_to(ROOT)} — create it with "
            "`python3 tests/check_layout.py --update` after checking the output"
        )
    return json.loads(BASELINE.read_text())


def compare(name: str, expected: list[list], actual: list[list]) -> tuple[bool, str]:
    if len(expected) != len(actual):
        return False, f"span count changed: {len(expected)} -> {len(actual)}"
    for index, (want, got) in enumerate(zip(expected, actual)):
        if want[3] != got[3]:
            return False, f"span {index} text {want[3]!r} -> {got[3]!r}"
        if want[0] != got[0]:
            return False, f"span {index} ({want[3]!r}) moved from page {want[0]} to {got[0]}"
        dx, dy = got[1] - want[1], got[2] - want[2]
        if abs(dx) > TOLERANCE or abs(dy) > TOLERANCE:
            return False, f"span {index} ({want[3][:30]!r}) moved by dx={dx:+.2f} dy={dy:+.2f}"
    return True, f"{len(actual)} spans unmoved"


def all_checks() -> list[tuple[str, bool, str]]:
    baseline = load_baseline()
    actual = current_fingerprint()
    results = []
    for name in sorted(set(baseline) | set(actual)):
        if name not in baseline:
            results.append((name, False, "not in baseline"))
        elif name not in actual:
            results.append((name, False, "PDF missing — run `make examples` first"))
        else:
            ok, detail = compare(name, baseline[name], actual[name])
            results.append((name, ok, detail))
    return results


# ---- pytest-discoverable wrappers ----------------------------------------


def test_layout_matches_baseline():
    failures = [f"{name}: {detail}" for name, ok, detail in all_checks() if not ok]
    assert not failures, "rendered layout changed:\n  " + "\n  ".join(failures)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="check every example PDF")
    parser.add_argument(
        "--update",
        action="store_true",
        help="rewrite the baseline from the current PDFs (only after reviewing them)",
    )
    args = parser.parse_args()

    if args.update:
        BASELINE.write_text(json.dumps(current_fingerprint(), indent=1) + "\n")
        print(f"wrote {BASELINE.relative_to(ROOT)}")
        return 0

    ok = True
    for name, passed, detail in all_checks():
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<34} {detail}")
        ok = ok and passed
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
