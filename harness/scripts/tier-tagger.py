#!/usr/bin/env python3
"""tier-tagger.py — Obsidian 05-wiki/ 파일에 tier frontmatter 주입.

- sources/*, entities/* → tier: raw
- concepts/*, analyses/* → tier: distilled
- distilled/*, synthesized/* → 폴더명 그대로

이미 tier가 있으면 skip. frontmatter 없으면 생성.
"""

from pathlib import Path
import re
import sys

VAULT = Path("C:/Users/AIcreator/Obsidian-Vault/05-wiki")

TIER_MAP = {
    "sources": "raw",
    "entities": "raw",
    "concepts": "distilled",
    "analyses": "distilled",
    "distilled": "distilled",
    "synthesized": "synthesized",
}

FM_PATTERN = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def process_file(path: Path, tier: str) -> str:
    """Return status: added / updated / skipped / error"""
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as e:
        return f"error: {e}"

    m = FM_PATTERN.match(text)
    if m:
        fm = m.group(1)
        if re.search(r"^tier\s*:", fm, re.MULTILINE):
            return "skipped"
        new_fm = fm.rstrip() + f"\ntier: {tier}\n"
        new_text = f"---\n{new_fm}---\n" + text[m.end():]
        status = "updated"
    else:
        new_text = f"---\ntier: {tier}\n---\n\n" + text
        status = "added"

    try:
        path.write_text(new_text, encoding="utf-8", newline="\n")
    except Exception as e:
        return f"error: {e}"

    return status


def main() -> int:
    counts = {"added": 0, "updated": 0, "skipped": 0, "error": 0}

    for subfolder, tier in TIER_MAP.items():
        folder = VAULT / subfolder
        if not folder.exists():
            continue
        for f in folder.glob("*.md"):
            if f.name.lower() == "readme.md":
                continue
            status = process_file(f, tier)
            key = status if status in counts else "error"
            counts[key] = counts.get(key, 0) + 1
            if key == "error":
                print(f"  ERROR {f.name}: {status}", file=sys.stderr)

    print(f"tier 태깅 결과:")
    print(f"  added:   {counts['added']}")
    print(f"  updated: {counts['updated']}")
    print(f"  skipped: {counts['skipped']}")
    print(f"  error:   {counts['error']}")
    return 0 if counts["error"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
