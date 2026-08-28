#!/usr/bin/env python3
"""Compute WCAG contrast ratios for every colour token against the page
background, and fail if any text-bearing token drops below the 4.5:1 AA
floor. Run before trusting any hex value hardcoded in src/tokens.typ or
cited in the spec — never eyeball these.
"""
import sys


def srgb_to_linear(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(hex_color):
    hex_color = hex_color.lstrip("#")
    r, g, b = (int(hex_color[i : i + 2], 16) for i in (0, 2, 4))
    r, g, b = (srgb_to_linear(v) for v in (r, g, b))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(hex_a, hex_b):
    la, lb = relative_luminance(hex_a), relative_luminance(hex_b)
    lighter, darker = max(la, lb), min(la, lb)
    return (lighter + 0.05) / (darker + 0.05)


BG = "#ffffff"

TOKENS = {
    "fg": "#3c3836",
    "muted": "#7c6f64",
    "secondary": "#076678",
    "accent-red": "#af3a03",
    "accent-green": "#157d00",
    "friggeri-blue": "#008194",
    "friggeri-red": "#eb0054",
    "friggeri-orange": "#ad6000",
    "friggeri-green": "#628000",
    "friggeri-purple": "#a638ff",
}

AA_FLOOR = 4.5


def main():
    print(f"{'token':<18}{'hex':<10}{'contrast on white':<20}verdict")
    failed = []
    for name, hexval in TOKENS.items():
        ratio = contrast_ratio(hexval, BG)
        verdict = "PASS" if ratio >= AA_FLOOR else "FAIL"
        if ratio < AA_FLOOR:
            failed.append(name)
        print(f"{name:<18}{hexval:<10}{ratio:<20.2f}{verdict}")

    if failed:
        print(f"\nFAILED AA floor ({AA_FLOOR}:1): {', '.join(failed)}", file=sys.stderr)
        sys.exit(1)
    print("\nAll tokens clear the AA floor.")


if __name__ == "__main__":
    main()
