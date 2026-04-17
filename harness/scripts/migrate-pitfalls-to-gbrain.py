"""
Migrate PITFALLS.md (P-001 ~ P-NNN) into gbrain as individual pages.
Uses subprocess to avoid shell escape issues that broke the previous bash-based migration.
"""
import re
import subprocess
import sys
from pathlib import Path

SOURCE = Path("D:/jamesclew/harness/archive/PITFALLS-2026-04-17.md")
GBRAIN = "C:/Users/AIcreator/AppData/Roaming/npm/gbrain.cmd"


def slugify(text: str, max_words: int = 5) -> str:
    """Convert title to kebab-case slug, English keywords only, length-bounded."""
    # Strip non-ASCII and special chars, keep alphanumeric + spaces + hyphens
    cleaned = re.sub(r"[^\w\s-]", " ", text, flags=re.UNICODE)
    # Convert to lowercase, split on whitespace, drop Korean/empty tokens
    words = []
    for w in cleaned.lower().split():
        ascii_only = re.sub(r"[^a-z0-9-]", "", w)
        if ascii_only and len(ascii_only) > 1:
            words.append(ascii_only)
    if not words:
        return "untitled"
    return "-".join(words[:max_words])


def parse_pitfalls(content: str):
    """Yield (id_num, title, body) for each `## [P-NNN] Title` section."""
    # Split on `## [P-NNN]` headers (lookahead to keep header in chunk)
    pattern = r"(?=^## \[P-\d+\])"
    chunks = re.split(pattern, content, flags=re.MULTILINE)
    for chunk in chunks:
        chunk = chunk.strip()
        m = re.match(r"^## \[P-(\d+)\]\s*(.+?)$", chunk, flags=re.MULTILINE)
        if not m:
            continue
        id_num = int(m.group(1))
        title = m.group(2).strip()
        # Strip the header line, keep the body (drop trailing `---` if present)
        body = chunk[m.end():].strip()
        body = re.sub(r"\n---\s*$", "", body).strip()
        yield id_num, title, body


def gbrain_delete(slug: str) -> None:
    subprocess.run(
        [GBRAIN, "delete", slug],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )


def gbrain_put(slug: str, content: str) -> tuple[bool, str]:
    result = subprocess.run(
        [GBRAIN, "put", slug, "--content", content],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    return result.returncode == 0, (result.stdout or "") + (result.stderr or "")


def list_existing_pitfalls() -> list[str]:
    """Return list of slugs that start with 'pitfall-'."""
    result = subprocess.run(
        [GBRAIN, "list", "-n", "200"],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    slugs = []
    for line in result.stdout.splitlines():
        # Format: "slug\ttype\tdate\ttitle"
        parts = line.split("\t")
        if parts and parts[0].startswith("pitfall-"):
            slugs.append(parts[0])
    return slugs


def main() -> int:
    if not SOURCE.exists():
        print(f"[error] source not found: {SOURCE}", file=sys.stderr)
        return 1

    text = SOURCE.read_text(encoding="utf-8")

    # Step 1: clean up bad imports from previous attempt
    existing = list_existing_pitfalls()
    print(f"[cleanup] removing {len(existing)} stale pitfall pages")
    for slug in existing:
        gbrain_delete(slug)

    # Step 2: parse + import
    success = 0
    failed = []
    for id_num, title, body in parse_pitfalls(text):
        slug = f"pitfall-{id_num:03d}-{slugify(title)}"
        # Build YAML frontmatter + body
        page = (
            "---\n"
            f"type: pitfall\n"
            f"id: P-{id_num:03d}\n"
            f"title: {title}\n"
            "tags: [pitfall, jamesclew]\n"
            "---\n\n"
            f"# P-{id_num:03d}: {title}\n\n"
            f"{body}\n"
        )
        ok, log = gbrain_put(slug, page)
        if ok:
            success += 1
            print(f"  OK   {slug}")
        else:
            failed.append((slug, log[:200]))
            print(f"  FAIL {slug}: {log[:100]}")

    print(f"\n[summary] success={success}, failed={len(failed)}, total={success+len(failed)}")
    if failed:
        print("[failed slugs]")
        for slug, log in failed:
            print(f"  {slug}: {log}")
    return 0 if not failed else 2


if __name__ == "__main__":
    sys.exit(main())
