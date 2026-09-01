#!/usr/bin/env python3
"""Verify every vertical/indent token in src/tokens.typ is a literal `N * u`
multiple of the single base unit, not an independently hand-tuned value.
Run before trusting a spacing constant — never eyeball whether the rhythm
still shares one denominator (design-cyber §4.4).
"""
import re
import sys
from pathlib import Path

TOKENS_FILE = Path(__file__).resolve().parent.parent / "src" / "tokens.typ"

# Every token that must be expressed as a literal multiple of `u`.
SPACING_TOKENS = (
    "space-bullet",
    "space-paragraph",
    "space-entry",
    "space-section-to-rule",
    "space-rule-to-content",
    "space-header-to-section",
    "space-header-line",
    "space-letter-paragraph",
    "body-indent",
)

U_RE = re.compile(r'^#let u = ([\d.]+)pt$', re.MULTILINE)
TOKEN_RE_TEMPLATE = r'^#let {name} = ([\d.]+) \* u$'


def main():
    src = TOKENS_FILE.read_text()

    u_match = U_RE.search(src)
    if u_match is None:
        print("FAIL: no literal `#let u = <N>pt` found in tokens.typ", file=sys.stderr)
        sys.exit(1)
    u_pt = float(u_match.group(1))

    print(f"{'token':<28}{'multiplier':<14}{'absolute':<12}status")
    failed = []
    for name in SPACING_TOKENS:
        pattern = re.compile(TOKEN_RE_TEMPLATE.format(name=re.escape(name)), re.MULTILINE)
        match = pattern.search(src)
        if match is None:
            failed.append(name)
            print(f"{name:<28}{'—':<14}{'—':<12}FAIL (not a literal N * u)")
            continue
        multiplier = float(match.group(1))
        absolute = multiplier * u_pt
        print(f"{name:<28}{multiplier:<14}{absolute:<12.2f}PASS")

    if failed:
        print(f"\nFAILED — not tied to `u`: {', '.join(failed)}", file=sys.stderr)
        sys.exit(1)
    print(f"\nAll spacing tokens are literal multiples of u ({u_pt}pt).")


if __name__ == "__main__":
    main()
