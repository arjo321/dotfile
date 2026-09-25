#!/usr/bin/env python3
"""Regenerate emojis.js (the QML module) from emojis.json.

Edit emojis.json, then run:  python3 gen_js.py
"""
import json
import pathlib

here = pathlib.Path(__file__).resolve().parent
data = json.loads((here / "emojis.json").read_text(encoding="utf-8"))

# Catch malformed entries before they become invisible/missing cells in QML.
# A previous data typo used a letter sequence instead of an emoji; requiring a
# non-empty, whitespace-free glyph keeps future edits safe.
invalid = [
    entry for entry in data.get("emojis", [])
    if not isinstance(entry.get("e"), str)
    or not entry["e"]
    or any(char.isspace() for char in entry["e"])
]
if invalid:
    raise SystemExit(f"invalid emoji glyph entries: {invalid[:3]}")

js = (
    "// Generated from emojis.json — edit the JSON, then regenerate with:\n"
    "//   python3 gen_js.py\n"
    "// Plain QML JS module (no 'pragma Library': quickshell's runtime parser\n"
    "// rejects the pragma directive at import time).\n"
    "\n"
    "var categories = "
    + json.dumps(data["categories"], ensure_ascii=False, indent=2)
    + ";\n\n"
    "var data = "
    + json.dumps(data["emojis"], ensure_ascii=False, indent=2)
    + ";\n"
)
(here / "emojis.js").write_text(js, encoding="utf-8")
print(f"wrote emojis.js: {len(data['emojis'])} emoji, {len(data['categories'])} categories")
