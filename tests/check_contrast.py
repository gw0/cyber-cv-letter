"""WCAG AA (4.5:1 against white) contrast check on every text-bearing colour
token in src/theme.typ. Colours are parsed out of theme.typ itself (not
duplicated by hand here) so this check can't silently drift from the
tokens it's meant to be verifying. Both a CLI (--all) and pytest-
discoverable functions.
"""

import argparse
import re
import sys
from pathlib import Path

THEME_FILE = Path(__file__).resolve().parent.parent / "src" / "theme.typ"
AA_FLOOR = 4.5
WHITE = (1.0, 1.0, 1.0)

# `bg` is the page background, not text — excluded from the check.
EXCLUDED_TOKENS = {"bg"}


def read_theme_source() -> str:
    return THEME_FILE.read_text()


def parse_named_colors(source: str) -> dict[str, str]:
    """Top-level `#let name = rgb("#hex")` tokens (excludes aliases like
    `#let x = muted`, which resolve to an already-checked token)."""
    colors = {}
    for m in re.finditer(r'^#let ([a-z0-9-]+) = rgb\("(#[0-9a-fA-F]{6})"\)\s*$', source, re.MULTILINE):
        name, hexval = m.group(1), m.group(2)
        if name not in EXCLUDED_TOKENS:
            colors[name] = hexval
    return colors


def parse_accent_presets(source: str) -> dict[str, list[str]]:
    """Maps each accent preset name to its list of hex colours."""
    m = re.search(r"#let accent-presets = \((.*?)\n\)\n", source, re.DOTALL)
    if not m:
        raise AssertionError("could not find `#let accent-presets = (...)` in src/theme.typ")
    body = m.group(1)
    presets = {}
    for entry_m in re.finditer(r"([a-z0-9-]+):\s*\(([^)]*)\)", body):
        name = entry_m.group(1)
        hexes = re.findall(r'"(#[0-9a-fA-F]{6})"', entry_m.group(2))
        presets[name] = hexes
    return presets


def hex_to_rgb(hexval: str) -> tuple[float, float, float]:
    hexval = hexval.lstrip("#")
    return tuple(int(hexval[i : i + 2], 16) / 255 for i in (0, 2, 4))


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb: tuple[float, float, float]) -> float:
    r, g, b = (srgb_to_linear(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(hex_a: str, hex_b: str) -> float:
    l1 = relative_luminance(hex_to_rgb(hex_a))
    l2 = relative_luminance(hex_to_rgb(hex_b))
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def collect_tokens() -> dict[str, str]:
    source = read_theme_source()
    tokens = parse_named_colors(source)
    for preset_name, hexes in parse_accent_presets(source).items():
        for i, hexval in enumerate(hexes):
            label = f"accent-presets.{preset_name}[{i}]" if len(hexes) > 1 else f"accent-presets.{preset_name}"
            tokens[label] = hexval
    return tokens


def check_all_tokens() -> list[tuple[str, str, float, bool]]:
    results = []
    for name, hexval in collect_tokens().items():
        ratio = contrast_ratio(hexval, "#ffffff")
        results.append((name, hexval, ratio, ratio >= AA_FLOOR))
    return results


def test_all_tokens_clear_wcag_aa():
    results = check_all_tokens()
    failures = [(name, hexval, ratio) for name, hexval, ratio, ok in results if not ok]
    assert not failures, f"tokens below WCAG AA {AA_FLOOR}:1 against white: {failures}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="check every colour token")
    parser.parse_args()

    results = check_all_tokens()
    ok = True
    for name, hexval, ratio, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"{status}  {name:<28} {hexval}  {ratio:.2f}:1")
        ok = ok and passed
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
