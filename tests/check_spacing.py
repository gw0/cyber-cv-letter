"""Asserts every named spacing token in src/theme.typ is a literal N * u
multiple of the base unit — the mechanical check that keeps the token set
in src/theme.typ from drifting apart independently over time. Both a CLI
(--all) and pytest-discoverable functions.
"""

import argparse
import re
import sys
from pathlib import Path

THEME_FILE = Path(__file__).resolve().parent.parent / "src" / "theme.typ"

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


def test_base_unit_present():
    get_base_unit(read_theme_source())


def test_all_spacing_tokens_are_literal_multiples():
    results = check_all_tokens()
    failures = [name for name, ok, _ in results if not ok]
    assert not failures, f"non-literal spacing tokens: {failures}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="check every spacing token")
    parser.parse_args()

    results = check_all_tokens()
    ok = True
    for name, passed, detail in results:
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<28} {detail}")
        ok = ok and passed
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
