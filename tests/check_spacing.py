"""Asserts every named design token in src/theme.typ — spacing and font
size — is expressed as a literal, and that no font-size call site outside
theme.typ falls back to a bare pt literal instead of a named token. This is
the mechanical check that keeps a token set from drifting apart
independently over time. Both a CLI (--all) and pytest-discoverable
functions.
"""

import argparse
import re
import sys
from pathlib import Path

THEME_FILE = Path(__file__).resolve().parent.parent / "src" / "theme.typ"
SRC_DIR = THEME_FILE.parent

SPACING_TOKENS = (
    "space-paragraph",
    "space-bullet",
    "space-entry",
    "space-section-to-rule",
    "space-rule-to-content",
    "space-header-to-section",
    "space-header-line",
    "body-indent",
    "space-code-indent",
    "mark-gutter",
    "logo-width",
    "logo-height",
    "logo-gutter",
)

# The type scale (src/theme.typ) — each backs 2+ call sites that must move
# together (see specs/20260902-simplify.md §9).
SIZE_TOKENS = (
    "size-header-name",
    "size-section-header",
    "size-entry-title",
    "size-body",
    "size-small",
    "size-footer",
)

BARE_SIZE_PATTERN = re.compile(r"size:\s*[\d.]+pt")


def read_theme_source() -> str:
    return THEME_FILE.read_text()


def get_base_unit(source: str) -> float:
    m = re.search(r"^#let u = ([\d.]+)pt\s*$", source, re.MULTILINE)
    if not m:
        raise AssertionError("could not find `#let u = <N>pt` in src/theme.typ")
    return float(m.group(1))


def get_token_multiple(source: str, name: str) -> float:
    pattern = rf"^#let {re.escape(name)} = ([\d.]+) \* u\b"
    m = re.search(pattern, source, re.MULTILINE)
    if not m:
        raise AssertionError(
            f"token `{name}` is not expressed as a literal `N * u` in src/theme.typ"
        )
    return float(m.group(1))


def get_size_token_value(source: str, name: str) -> float:
    pattern = rf"^#let {re.escape(name)} = ([\d.]+)pt\b"
    m = re.search(pattern, source, re.MULTILINE)
    if not m:
        raise AssertionError(
            f"token `{name}` is not expressed as a literal `Npt` in src/theme.typ"
        )
    return float(m.group(1))


def check_all_tokens() -> list[tuple[str, bool, str]]:
    source = read_theme_source()
    get_base_unit(source)  # asserts `u` itself is present
    results = []
    for name in SPACING_TOKENS:
        try:
            multiple = get_token_multiple(source, name)
            results.append((name, True, f"{multiple} * u"))
        except AssertionError as e:
            results.append((name, False, str(e)))
    return results


def check_all_size_tokens() -> list[tuple[str, bool, str]]:
    source = read_theme_source()
    results = []
    for name in SIZE_TOKENS:
        try:
            value = get_size_token_value(source, name)
            results.append((name, True, f"{value}pt"))
        except AssertionError as e:
            results.append((name, False, str(e)))
    return results


def find_bare_size_literals() -> list[str]:
    """Every `size: Npt` in src/*.typ outside theme.typ's own token
    definitions — each call site should reference a named size-* token
    instead."""
    offenders = []
    for path in sorted(SRC_DIR.glob("*.typ")):
        if path == THEME_FILE:
            continue
        for lineno, line in enumerate(path.read_text().splitlines(), start=1):
            if BARE_SIZE_PATTERN.search(line):
                offenders.append(f"{path.name}:{lineno}: {line.strip()}")
    return offenders


def test_base_unit_present():
    get_base_unit(read_theme_source())


def test_all_spacing_tokens_are_literal_multiples():
    results = check_all_tokens()
    failures = [name for name, ok, _ in results if not ok]
    assert not failures, f"non-literal spacing tokens: {failures}"


def test_all_size_tokens_are_literal_pt():
    results = check_all_size_tokens()
    failures = [name for name, ok, _ in results if not ok]
    assert not failures, f"non-literal size tokens: {failures}"


def test_no_bare_size_literals_outside_theme():
    offenders = find_bare_size_literals()
    assert not offenders, f"bare `size: Npt` literals outside theme.typ: {offenders}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="check every design token")
    parser.parse_args()

    ok = True

    for name, passed, detail in check_all_tokens():
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<28} {detail}")
        ok = ok and passed

    for name, passed, detail in check_all_size_tokens():
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<28} {detail}")
        ok = ok and passed

    offenders = find_bare_size_literals()
    if offenders:
        ok = False
        print("FAIL  bare size: Npt literals outside theme.typ:")
        for offender in offenders:
            print(f"      {offender}")
    else:
        print("PASS  no bare size: Npt literals outside theme.typ")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
